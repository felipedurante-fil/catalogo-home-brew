import SwiftUI
import SwiftData

struct PackageListView: View {
    let selection: SidebarSelection
    @Binding var selectedPackage: Package?

    @Environment(CatalogViewModel.self) private var catalogViewModel
    @Environment(SearchTranslator.self) private var searchTranslator
    @Environment(\.modelContext) private var modelContext

    // Busca manual (não @Query) guardada em @State: um @Query fica "vivo" e reavalia/revalida
    // sua coleção inteira a cada mutação de QUALQUER Package no contexto (ex.: cada tradução
    // chegando em background) — com ~16 mil objetos isso é caro e ficava perceptível como
    // travamentos durante a navegação normal, não só ao trocar de faceta.
    // Como cada Package é observável por si só, mutações em objetos que já estão aqui (ex.:
    // instalar um pacote, uma tradução chegando) continuam atualizando a linha na hora — só
    // precisamos refazer essa busca quando o CONJUNTO de pacotes muda de verdade (sync completo).
    @State private var allPackages: [Package] = []
    @State private var searchText = ""
    @State private var bulkUpdateRunner = BrewCommandRunner()
    @State private var showBulkLog = false
    @State private var filteredPackages: [Package] = []
    // Tradução PT→EN do termo de busca (ex.: "visualizador de pdf" → "pdf viewer"), pra
    // cruzar com as descrições originais em inglês que ainda não foram traduzidas.
    @State private var translatedSearchText = ""

    init(selection: SidebarSelection, selectedPackage: Binding<Package?>) {
        self.selection = selection
        self._selectedPackage = selectedPackage
    }

    private func loadAllPackages() {
        let descriptor = FetchDescriptor<Package>(sortBy: [SortDescriptor(\.name)])
        allPackages = (try? modelContext.fetch(descriptor)) ?? []
        recomputeFilteredPackages()
    }

    private func recomputeFilteredPackages() {
        var result: [Package]
        switch selection {
        case .all:
            result = allPackages
        case .kind(let kind):
            result = allPackages.filter { $0.kind == kind }
        case .installed:
            result = allPackages.filter { $0.isInstalled }
        case .outdated:
            result = allPackages.filter { $0.isOutdated }
        case .deprecated:
            result = allPackages.filter { $0.isDeprecated || $0.isDisabled }
        case .tap(let tap):
            result = allPackages.filter { $0.tap == tap }
        case .category(let category):
            result = allPackages.filter { $0.category == category }
        }

        if !searchText.isEmpty {
            // Cruza com o termo original (PT ou EN, como o usuário digitou) e com a
            // tradução EN dele (pra achar pacotes cuja descrição em inglês ainda não foi
            // traduzida — ex.: buscar "visualizador de pdf" também acha "PDF viewer").
            let needles = [searchText, translatedSearchText].filter { !$0.isEmpty }
            result = result.filter { package in
                needles.contains { needle in
                    package.name.localizedCaseInsensitiveContains(needle) ||
                    package.desc.localizedCaseInsensitiveContains(needle) ||
                    (package.descPT?.localizedCaseInsensitiveContains(needle) ?? false) ||
                    package.category.title.localizedCaseInsensitiveContains(needle)
                }
            }
        }
        filteredPackages = result
    }

    var body: some View {
        List(selection: $selectedPackage) {
            ForEach(filteredPackages) { package in
                PackageRow(package: package).tag(package)
            }
        }
        // Recria a List (e a NSTableView por baixo) a cada troca de faceta OU sempre que a
        // busca liga/desliga — mais simples e confiável do que deixar a MESMA tabela absorver
        // uma mudança brusca no número de linhas (ex.: limpar a busca faz pular de uma dúzia
        // de resultados filtrados pros ~16 mil da faceta inteira de uma vez), que em teste real
        // do usuário chegou a derrubar o app. Também é o que já resolvia o scroll-to-top.
        .id("\(selection)|\(searchText.isEmpty)")
        .onChange(of: selection) {
            // Trocar de categoria/faceta limpa a busca — não faz sentido continuar aplicando
            // um termo digitado pra outra faceta na nova seleção.
            searchText = ""
            translatedSearchText = ""
            recomputeFilteredPackages()
        }
        .searchable(text: $searchText, prompt: "Buscar pacotes")
        .navigationTitle(selection.title)
        .toolbar {
            if selection == .installed || selection == .outdated {
                ToolbarItem(placement: .automatic) {
                    Button {
                        showBulkLog = true
                        try? bulkUpdateRunner.run(["upgrade"])
                    } label: {
                        Label("Atualizar tudo", systemImage: "arrow.up.circle")
                    }
                    .disabled(bulkUpdateRunner.isRunning)
                }
            }
        }
        .sheet(isPresented: $showBulkLog) {
            CommandLogView(runner: bulkUpdateRunner, title: "brew upgrade") {
                Task { await catalogViewModel.refreshInstalledStatus(context: modelContext) }
            }
        }
        .onAppear { loadAllPackages() }
        .onChange(of: searchText) {
            // Filtra na hora com o termo literal (acha nomes/palavras em comum tipo "pdf"
            // de cara); a tradução chega um pouco depois e amplia o resultado.
            recomputeFilteredPackages()
        }
        .task(id: searchText) {
            guard !searchText.isEmpty else {
                translatedSearchText = ""
                return
            }
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            translatedSearchText = await searchTranslator.translate(searchText) ?? ""
            guard !Task.isCancelled else { return }
            recomputeFilteredPackages()
        }
        .onChange(of: catalogViewModel.lastSyncDate) { loadAllPackages() }
    }
}

private struct PackageRow: View {
    let package: Package

    var body: some View {
        HStack {
            Image(systemName: package.kind == .cask ? "app.badge" : "terminal")
                .foregroundStyle(.secondary)
            VStack(alignment: .leading) {
                Text(package.name).font(.headline)
                Text(package.displayDescription).font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer()
            if package.isOutdated {
                Image(systemName: "arrow.up.circle.fill").foregroundStyle(.orange)
            } else if package.isInstalled {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
            }
        }
        .padding(.vertical, 2)
    }
}
