import Foundation

/// Lista de taps distintos do catálogo, calculada uma vez durante o `CatalogService.sync`
/// (direto dos DTOs baixados, sem tocar no SwiftData) e cacheada no UserDefaults.
///
/// Evita a `SidebarView` precisar de um `@Query` vivo sobre os ~16 mil `Package` só pra
/// extrair um punhado de nomes de tap — ter dois `@Query` (Sidebar + lista) rastreando o
/// catálogo inteiro ao mesmo tempo era uma fonte real de lentidão geral do app.
enum TapsStore {
    private static let key = "BrewCatalog.taps"

    static var taps: [String] {
        get { UserDefaults.standard.stringArray(forKey: key) ?? [] }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }
}
