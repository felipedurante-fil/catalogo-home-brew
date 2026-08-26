import Foundation
import Observation
import Translation

/// Traduz descrições de pacotes (EN → PT) sob demanda, conforme as Views pedem
/// (`enqueue`), usando o framework `Translation` da Apple (on-device).
///
/// Importante: a `TranslationSession` só é válida enquanto a closure do `.translationTask`
/// que a forneceu continuar "rodando" (suspensa em algum await). Se essa closure retornar,
/// o framework invalida a sessão — usá-la depois disso derruba o app com um assert interno.
/// Por isso `run(session:)` fica suspensa pra sempre (drenando a fila via AsyncStream) em vez
/// de só guardar a referência e retornar, como uma primeira versão fazia.
@Observable
final class TranslationQueue {
    private var pending: [Package] = []
    private var enqueuedIDs: Set<String> = []
    private var continuation: AsyncStream<Void>.Continuation?

    func enqueue(_ package: Package) {
        guard package.descPT == nil, !package.desc.isEmpty, !enqueuedIDs.contains(package.id) else { return }
        enqueuedIDs.insert(package.id)
        pending.append(package)
        continuation?.yield()
    }

    /// Chamar uma única vez a partir do `.translationTask` da View raiz e deixar rodando
    /// (via `await`) por toda a vida do app.
    func run(session: TranslationSession) async {
        let stream = AsyncStream<Void> { continuation in
            self.continuation = continuation
        }
        for await _ in stream {
            while !pending.isEmpty {
                if Task.isCancelled { return }

                // Traduz um lote pequeno (cada chamada precisa de await) e só então aplica
                // todas as gravações de `descPT` em sequência síncrona, sem await entre elas —
                // isso deixa o SwiftData coalescer as mutações numa notificação só pro @Query
                // em vez de uma por item. Sem isso, cada tradução chegando individualmente
                // disparava uma invalidação/refiltragem própria na lista (~16 mil itens),
                // o que ficava perceptível como lentidão ao navegar durante uma rajada grande.
                var batch: [(Package, String)] = []
                for _ in 0..<5 {
                    guard !pending.isEmpty else { break }
                    let package = pending.removeFirst()
                    enqueuedIDs.remove(package.id)
                    if let text = await Self.translateWithTimeout(text: package.desc, session: session) {
                        batch.append((package, text))
                    }
                    // Se não voltou nada (falha ou timeout), o pacote continua mostrando o texto original.
                }
                for (package, text) in batch {
                    package.descPT = text
                }

                // Pequeno espaçamento entre lotes: aplicar mutações em sequência ininterrupta
                // demais parece contribuir pra instabilidades internas do SwiftData (observadas
                // como crashes esporádicos ao trocar de app durante uma rajada de traduções).
                try? await Task.sleep(for: .milliseconds(60))
            }
        }
    }

    /// `session.translate(_:)` roda numa Task destacada (prioridade alta, fora da MainActor)
    /// com um timeout de 6s — em teste real, uma chamada de tradução ficou ~12s sem devolver
    /// nada e a interface inteira parou de responder a teclado/cursor durante esse tempo,
    /// sinal de que a chamada estava prendendo a thread que também cuida da UI.
    private static func translateWithTimeout(text: String, session: TranslationSession) async -> String? {
        await withTaskGroup(of: String?.self) { group in
            group.addTask(priority: .userInitiated) {
                do {
                    return try await session.translate(text).targetText
                } catch {
                    return nil
                }
            }
            group.addTask {
                try? await Task.sleep(for: .seconds(6))
                return nil
            }
            let result = await group.next() ?? nil
            group.cancelAll()
            return result
        }
    }
}
