import Foundation
import Observation
import Translation

/// Traduz o termo de busca (PT → EN) sob demanda, pra poder cruzar com as descrições
/// originais em inglês do catálogo — assim buscar "visualizador de pdf" também encontra
/// pacotes cuja descrição (ainda não traduzida) diz "PDF viewer".
///
/// Mesma restrição de ciclo de vida do `TranslationQueue`: a `TranslationSession` só é válida
/// enquanto a closure do `.translationTask` que a forneceu continuar rodando, então `run(session:)`
/// fica suspensa pra sempre.
@Observable
final class SearchTranslator {
    private var pendingRequests: [(text: String, continuation: CheckedContinuation<String?, Never>)] = []
    private var continuation: AsyncStream<Void>.Continuation?

    func run(session: TranslationSession) async {
        let stream = AsyncStream<Void> { continuation in
            self.continuation = continuation
        }
        for await _ in stream {
            while !pendingRequests.isEmpty {
                if Task.isCancelled { return }
                let request = pendingRequests.removeFirst()
                let text = await Self.translateWithTimeout(text: request.text, session: session)
                request.continuation.resume(returning: text)
            }
        }
    }

    /// `session.translate(_:)` roda numa Task destacada (prioridade alta, mas fora da
    /// MainActor) — em teste real, um pedido de tradução ficou ~12s sem devolver nada e a
    /// interface inteira parou de responder a teclado/cursor durante esse tempo, sinal de
    /// que a chamada estava prendendo a thread que também cuida da UI. Um timeout de 6s
    /// garante que, mesmo se o serviço de tradução do sistema travar, a busca não fica
    /// travada esperando pra sempre — só deixa de mostrar os resultados "ampliados".
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

    func translate(_ text: String) async -> String? {
        guard !text.isEmpty else { return nil }
        return await withCheckedContinuation { continuation in
            pendingRequests.append((text, continuation))
            self.continuation?.yield()
        }
    }
}
