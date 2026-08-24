import Foundation

enum PricingHint: String, Codable {
    case free
    case paid
    case freemium
    case unknown

    var title: String {
        switch self {
        case .free: return "Grátis"
        case .paid: return "Pago"
        case .freemium: return "Freemium"
        case .unknown: return "Não informado"
        }
    }

    var systemImage: String {
        switch self {
        case .free: return "checkmark.circle"
        case .paid: return "dollarsign.circle"
        case .freemium: return "circle.lefthalf.filled"
        case .unknown: return "questionmark.circle"
        }
    }
}
