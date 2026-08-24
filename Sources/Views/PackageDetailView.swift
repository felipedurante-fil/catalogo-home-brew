import SwiftUI
import SwiftData

struct PackageDetailView: View {
    @Bindable var package: Package

    @Environment(CatalogViewModel.self) private var catalogViewModel
    @Environment(TranslationQueue.self) private var translationQueue
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL

    @State private var runner = BrewCommandRunner()
    @State private var showLog = false
    @State private var pendingAction: PendingAction?

    private enum PendingAction: String {
        case install = "Instalar"
        case uninstall = "Desinstalar"
        case upgrade = "Atualizar"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                if package.isDeprecated || package.isDisabled {
                    Label(
                        package.isDisabled ? "Este pacote foi desativado no Homebrew." : "Este pacote está descontinuado (deprecated).",
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .foregroundStyle(.orange)
                    .padding(8)
                    .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                }

                Text(package.displayDescription).font(.body)

                if let url = URL(string: package.homepage), !package.homepage.isEmpty {
                    Button {
                        openURL(url)
                    } label: {
                        Label(package.homepage, systemImage: "link")
                    }
                    .buttonStyle(.link)
                }

                Divider()

                infoRow("Versão", package.version)
                infoRow("Tap", package.tap)
                infoRow("Tipo", package.kind == .cask ? "Cask" : "Formula")
                infoRow("Funcionalidade", package.category.title)
                infoRow("Preço", package.pricingHint.title)
                if let license = package.license, !license.isEmpty {
                    infoRow("Licença", license)
                }
                if package.isInstalled, let installedVersion = package.installedVersion {
                    infoRow("Versão instalada", installedVersion)
                }
                if package.isKegOnly {
                    infoRow("Keg-only", "Sim")
                }
                if !package.dependencies.isEmpty {
                    infoRow("Dependências", package.dependencies.joined(separator: ", "))
                }
                if let caveats = package.caveats, !caveats.isEmpty {
                    Divider()
                    Text("Avisos").font(.headline)
                    Text(caveats).font(.system(.body, design: .monospaced))
                }

                Divider()
                actionButtons
            }
            .padding()
        }
        .navigationTitle(package.name)
        .onAppear { translationQueue.enqueue(package) }
        .sheet(isPresented: $showLog) {
            CommandLogView(runner: runner, title: pendingAction?.rawValue ?? "brew") {
                Task { await catalogViewModel.refreshInstalledStatus(context: modelContext) }
            }
        }
    }

    private var header: some View {
        HStack {
            Image(systemName: package.kind == .cask ? "app.badge" : "terminal")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading) {
                Text(package.name).font(.title).bold()
                Text(package.id).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Label(package.pricingHint.title, systemImage: package.pricingHint.systemImage)
                .font(.caption.bold())
                .foregroundStyle(pricingColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(pricingColor.opacity(0.12), in: Capsule())
        }
    }

    private var pricingColor: Color {
        switch package.pricingHint {
        case .free: return .green
        case .paid: return .orange
        case .freemium: return .blue
        case .unknown: return .secondary
        }
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label).foregroundStyle(.secondary).frame(width: 140, alignment: .leading)
            Text(value)
            Spacer()
        }
        .font(.callout)
    }

    @ViewBuilder
    private var actionButtons: some View {
        HStack {
            if !package.isInstalled {
                Button {
                    perform(.install, arguments: installArguments)
                } label: {
                    Label("Instalar", systemImage: "arrow.down.circle")
                }
                .buttonStyle(.borderedProminent)
            } else {
                if package.isOutdated {
                    Button {
                        perform(.upgrade, arguments: upgradeArguments)
                    } label: {
                        Label("Atualizar", systemImage: "arrow.up.circle")
                    }
                    .buttonStyle(.borderedProminent)
                }
                Button(role: .destructive) {
                    perform(.uninstall, arguments: uninstallArguments)
                } label: {
                    Label("Desinstalar", systemImage: "trash")
                }
            }
        }
        .disabled(package.isDisabled || runner.isRunning)
    }

    private var installArguments: [String] {
        package.kind == .cask ? ["install", "--cask", package.id] : ["install", package.id]
    }

    private var uninstallArguments: [String] {
        package.kind == .cask ? ["uninstall", "--cask", package.id] : ["uninstall", package.id]
    }

    private var upgradeArguments: [String] {
        package.kind == .cask ? ["upgrade", "--cask", package.id] : ["upgrade", package.id]
    }

    private func perform(_ action: PendingAction, arguments: [String]) {
        pendingAction = action
        showLog = true
        try? runner.run(arguments)
    }
}
