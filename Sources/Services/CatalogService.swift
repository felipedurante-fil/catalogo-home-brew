import Foundation
import SwiftData

enum CatalogServiceError: Error {
    case invalidResponse
}

enum CatalogService {
    private static let formulaURL = URL(string: "https://formulae.brew.sh/api/formula.json")!
    private static let caskURL = URL(string: "https://formulae.brew.sh/api/cask.json")!

    /// Baixa o catálogo completo (formula.json + cask.json), substitui tudo que está
    /// salvo localmente e grava em lotes para não segurar uma transação gigante.
    /// Roda inteiro numa Task destacada: o parse de ~16 mil itens + categorização
    /// é trabalho síncrono pesado que travaria a MainActor (e a janela nem apareceria)
    /// se rodasse na task do `.task` da View, que herda o contexto principal.
    static func sync(container: ModelContainer) async throws {
        try await Task.detached(priority: .userInitiated) {
            try await performSync(container: container)
        }.value
    }

    private static func performSync(container: ModelContainer) async throws {
        async let formulaFetch = URLSession.shared.data(from: formulaURL)
        async let caskFetch = URLSession.shared.data(from: caskURL)

        let (formulaData, formulaResponse) = try await formulaFetch
        let (caskData, caskResponse) = try await caskFetch

        guard
            (formulaResponse as? HTTPURLResponse)?.statusCode == 200,
            (caskResponse as? HTTPURLResponse)?.statusCode == 200
        else {
            throw CatalogServiceError.invalidResponse
        }

        let decoder = JSONDecoder()
        let formulae = try decoder.decode([FormulaDTO].self, from: formulaData)
        let casks = try decoder.decode([CaskDTO].self, from: caskData)

        let context = ModelContext(container)
        context.autosaveEnabled = false

        try context.delete(model: Package.self)
        try context.save()

        var pending = 0
        func insert(_ package: Package) throws {
            context.insert(package)
            pending += 1
            // Lotes maiores = menos saves = menos notificações de mudança disparando
            // reload da List (~16 mil linhas) durante a carga inicial.
            if pending >= 4000 {
                try context.save()
                pending = 0
            }
        }

        for formula in formulae {
            let desc = formula.desc ?? ""
            try insert(
                Package(
                    id: formula.fullName,
                    name: formula.name,
                    kind: .formula,
                    tap: formula.tap,
                    category: PackageCategorizer.category(id: formula.fullName, name: formula.name, desc: desc),
                    desc: desc,
                    homepage: formula.homepage ?? "",
                    version: formula.versions.stable ?? "",
                    dependencies: formula.dependencies,
                    caveats: formula.caveats,
                    isKegOnly: formula.kegOnly,
                    isDeprecated: formula.deprecated,
                    isDisabled: formula.disabled,
                    license: formula.license,
                    pricingHint: .free // formulae do Homebrew são sempre open-source/gratuitas
                )
            )
        }

        for cask in casks {
            let name = cask.name.first ?? cask.token
            let desc = cask.desc ?? ""
            try insert(
                Package(
                    id: cask.fullToken,
                    name: name,
                    kind: .cask,
                    tap: cask.tap,
                    category: PackageCategorizer.category(id: cask.fullToken, name: name, desc: desc),
                    desc: desc,
                    homepage: cask.homepage ?? "",
                    version: cask.version ?? "",
                    dependencies: cask.dependsOnFormulae,
                    caveats: cask.caveats,
                    isDeprecated: cask.deprecated,
                    isDisabled: cask.disabled,
                    pricingHint: PricingCategorizer.hint(desc: desc)
                )
            )
        }

        try context.save()

        // Calculado direto dos DTOs (sem query no SwiftData) e cacheado — ver TapsStore.
        TapsStore.taps = Set(formulae.map(\.tap)).union(casks.map(\.tap)).sorted()

        try await InstalledStatusService.refresh(in: context)
    }
}
