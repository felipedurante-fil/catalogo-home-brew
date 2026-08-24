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
                do {
                    let response = try await session.translate(request.text)
                    request.continuation.resume(returning: response.targetText)
                } catch {
                    request.continuation.resume(returning: nil)
                }
            }
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
