import SwiftUI
import SwiftData

struct SidebarView: View {
    @Binding var selection: SidebarSelection?
    @Environment(CatalogViewModel.self) private var catalogViewModel

    // Lido do TapsStore (calculado no CatalogService.sync direto dos DTOs) em vez de um
    // @Query sobre os ~16 mil Package — ter dois @Query rastreando o catálogo inteiro ao
    // mesmo tempo (Sidebar + lista) era uma fonte real de lentidão geral do app.
    @State private var taps: [String] = TapsStore.taps

    var body: some View {
        List(selection: $selection) {
            Section("Catálogo") {
                Label("Tudo", systemImage: "square.grid.2x2").tag(SidebarSelection.all)
                Label("Formulae", systemImage: "terminal").tag(SidebarSelection.kind(.formula))
                Label("Casks", systemImage: "app.badge").tag(SidebarSelection.kind(.cask))
            }
            Section("Meu Mac") {
                Label("Instalados", systemImage: "checkmark.circle").tag(SidebarSelection.installed)
                Label("Atualizações disponíveis", systemImage: "arrow.up.circle").tag(SidebarSelection.outdated)
            }
            Section("Status") {
                Label("Descontinuados", systemImage: "exclamationmark.triangle").tag(SidebarSelection.deprecated)
            }
            Section("Funcionalidades") {
                ForEach(PackageCategory.allCases.filter { $0 != .outros }, id: \.self) { category in
                    Label(category.title, systemImage: category.systemImage).tag(SidebarSelection.category(category))
                }
                Label(PackageCategory.outros.title, systemImage: PackageCategory.outros.systemImage)
                    .tag(SidebarSelection.category(.outros))
            }
            if !taps.isEmpty {
                Section("Taps") {
                    ForEach(taps, id: \.self) { tap in
                        Label(tap, systemImage: "spigot").tag(SidebarSelection.tap(tap))
                    }
                }
            }
        }
        .navigationTitle("BrewCatalog")
        .onChange(of: catalogViewModel.lastSyncDate) {
            taps = TapsStore.taps
        }
    }
}
