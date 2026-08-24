import Foundation

/// O Homebrew não tem campo de preço para casks (só formulae têm `license`, e formulae são
/// sempre open-source/gratuitas por política do próprio Homebrew). Pra casks, tentamos uma
/// heurística por palavras-chave na descrição original em inglês — mesmo espírito da
/// categorização por funcionalidade: não é 100% precisa, mas dá um indicativo útil.
enum PricingCategorizer {
    private static let freemiumKeywords = ["freemium", "free trial", "free version", "trial version"]
    private static let paidKeywords = [
        "subscription", "license key", "premium", "paid app", "purchase", "pricing",
        "in-app purchase", "one-time purchase", "$",
    ]
    private static let freeKeywords = ["free", "open source", "open-source", "no cost", "gratis"]

    static func hint(desc: String) -> PricingHint {
        let text = desc.lowercased()
        guard !text.isEmpty else { return .unknown }

        if freemiumKeywords.contains(where: { text.contains($0) }) {
            return .freemium
        }
        if paidKeywords.contains(where: { text.contains($0) }) {
            return .paid
        }
        if freeKeywords.contains(where: { text.contains($0) }) {
            return .free
        }
        return .unknown
    }
}
