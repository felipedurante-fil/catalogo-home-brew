import SwiftUI
import SwiftData
import Translation

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allPackages: [Package]

    @State private var catalogViewModel = CatalogViewModel()
    @State private var selection: SidebarSelection? = .all
    @State private var selectedPackage: Package?
    @State private var showHomebrewMissingAlert = false

    @State private var translationQueue = TranslationQueue()
    @State private var translationConfiguration = TranslationSession.Configuration(
        source: Locale.Language(identifier: "en"),
        target: Locale.Language(identifier: "pt")
    )

    // Direção inversa (PT→EN), usada só pra traduzir o termo de busca e cruzar com as
    // descrições originais em inglês do catálogo — ver SearchTranslator.
    @State private var searchTranslator = SearchTranslator()
    @State private var searchTranslationConfiguration = TranslationSession.Configuration(
        source: Locale.Language(identifier: "pt"),
        target: Locale.Language(identifier: "en")
    )

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selection)
                .navigationSplitViewColumnWidth(min: 200, ideal: 220)
        } content: {
            if let selection {
                PackageListView(selection: selection, selectedPackage: $selectedPackage)
                    .navigationSplitViewColumnWidth(min: 260, ideal: 320)
            } else {
                ContentUnavailableView("Selecione uma categoria", systemImage: "square.grid.2x2")
            }
        } detail: {
            if let selectedPackage {
                PackageDetailView(package: selectedPackage)
                    .id(selectedPackage.id)
            } else {
                ContentUnavailableView("Selecione um pacote", systemImage: "shippingbox")
            }
        }
        .environment(catalogViewModel)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                if catalogViewModel.isSyncing {
                    ProgressView().controlSize(.small)
                } else {
                    Button {
                        Task { await catalogViewModel.syncCatalog(container: modelContext.container) }
                    } label: {
                        Label("Atualizar catálogo", systemImage: "arrow.clockwise")
                    }
                }
            }
        }
        .task {
            showHomebrewMissingAlert = catalogViewModel.homebrewMissing
            if !catalogViewModel.homebrewMissing, allPackages.isEmpty {
                await catalogViewModel.syncCatalog(container: modelContext.container)
            }
        }
        .alert("Homebrew não encontrado", isPresented: $showHomebrewMissingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Não encontrei o `brew` em /opt/homebrew ou /usr/local. Instale o Homebrew (brew.sh) e abra o app novamente.")
        }
        .translationTask(translationConfiguration) { session in
            await translationQueue.run(session: session)
        }
        .translationTask(searchTranslationConfiguration) { session in
            await searchTranslator.run(session: session)
        }
        .environment(translationQueue)
        .environment(searchTranslator)
    }
}
