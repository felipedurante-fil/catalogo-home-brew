import Foundation
import SwiftData

enum PackageKind: String, Codable {
    case formula
    case cask
}

@Model
final class Package {
    @Attribute(.unique) var id: String   // full_name (formula) ou full_token (cask)
    var name: String
    var kind: PackageKind
    var tap: String
    var category: PackageCategory
    var desc: String
    var descPT: String?
    var homepage: String
    var version: String
    var dependencies: [String]
    var caveats: String?
    var isKegOnly: Bool
    var isDeprecated: Bool
    var isDisabled: Bool
    var isInstalled: Bool
    var isOutdated: Bool
    var installedVersion: String?
    var license: String?          // só formulae — o Homebrew não expõe isso pra casks
    var pricingHint: PricingHint  // formulae: sempre .free; casks: heurística por palavras-chave

    init(
        id: String,
        name: String,
        kind: PackageKind,
        tap: String,
        category: PackageCategory = .outros,
        desc: String,
        descPT: String? = nil,
        homepage: String,
        version: String,
        dependencies: [String] = [],
        caveats: String? = nil,
        isKegOnly: Bool = false,
        isDeprecated: Bool = false,
        isDisabled: Bool = false,
        isInstalled: Bool = false,
        isOutdated: Bool = false,
        installedVersion: String? = nil,
        license: String? = nil,
        pricingHint: PricingHint = .unknown
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.tap = tap
        self.category = category
        self.desc = desc
        self.descPT = descPT
        self.homepage = homepage
        self.version = version
        self.dependencies = dependencies
        self.caveats = caveats
        self.isKegOnly = isKegOnly
        self.isDeprecated = isDeprecated
        self.isDisabled = isDisabled
        self.isInstalled = isInstalled
        self.isOutdated = isOutdated
        self.installedVersion = installedVersion
        self.license = license
        self.pricingHint = pricingHint
    }
}

extension Package {
    /// Identificador que o `brew` espera na linha de comando: full_name (formula) ou full_token (cask) — ambos já é o próprio `id`.
    var brewArgument: String { id }

    /// Descrição a exibir: prioriza a tradução em PT já cacheada, cai pro texto original
    /// em inglês enquanto a tradução não chega, e mostra um aviso fixo se não houver descrição nenhuma.
    var displayDescription: String {
        if let descPT, !descPT.isEmpty { return descPT }
        if desc.isEmpty { return "Sem descrição disponível." }
        return desc
    }
}
