import Foundation

enum SidebarSelection: Hashable {
    case all
    case kind(PackageKind)
    case installed
    case outdated
    case deprecated
    case tap(String)
    case category(PackageCategory)

    var title: String {
        switch self {
        case .all: return "Tudo"
        case .kind(.formula): return "Formulae"
        case .kind(.cask): return "Casks"
        case .installed: return "Instalados"
        case .outdated: return "Atualizações disponíveis"
        case .deprecated: return "Descontinuados"
        case .tap(let tap): return tap
        case .category(let category): return category.title
        }
    }
}
