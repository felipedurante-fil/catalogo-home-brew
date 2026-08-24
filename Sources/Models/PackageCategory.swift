import Foundation

enum PackageCategory: String, Codable, CaseIterable {
    case desenvolvimento
    case bancosDeDados
    case redes
    case seguranca
    case multimidia
    case ciencia
    case jogos
    case fontes
    case produtividade
    case sistema
    case outros

    var title: String {
        switch self {
        case .desenvolvimento: return "Desenvolvimento"
        case .bancosDeDados: return "Bancos de Dados"
        case .redes: return "Redes"
        case .seguranca: return "Segurança"
        case .multimidia: return "Multimídia"
        case .ciencia: return "Ciência e Dados"
        case .jogos: return "Jogos"
        case .fontes: return "Fontes"
        case .produtividade: return "Produtividade"
        case .sistema: return "Sistema"
        case .outros: return "Outros"
        }
    }

    var systemImage: String {
        switch self {
        case .desenvolvimento: return "hammer"
        case .bancosDeDados: return "cylinder.split.1x2"
        case .redes: return "network"
        case .seguranca: return "lock.shield"
        case .multimidia: return "play.rectangle"
        case .ciencia: return "chart.xyaxis.line"
        case .jogos: return "gamecontroller"
        case .fontes: return "textformat"
        case .produtividade: return "checklist"
        case .sistema: return "gearshape"
        case .outros: return "square.grid.2x2"
        }
    }
}
