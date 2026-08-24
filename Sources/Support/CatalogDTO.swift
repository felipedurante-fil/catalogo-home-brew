import Foundation

// Espelha só os campos que usamos de formulae.brew.sh/api/formula.json —
// Codable ignora automaticamente as dezenas de outros campos do JSON.
struct FormulaDTO: Decodable {
    let name: String
    let fullName: String
    let tap: String
    let desc: String?
    let license: String?
    let homepage: String?
    let versions: Versions
    let dependencies: [String]
    let caveats: String?
    let kegOnly: Bool
    let deprecated: Bool
    let disabled: Bool

    struct Versions: Decodable {
        let stable: String?
    }

    enum CodingKeys: String, CodingKey {
        case name, tap, desc, license, homepage, versions, dependencies, caveats
        case fullName = "full_name"
        case kegOnly = "keg_only"
        case deprecated, disabled
    }
}

// Espelha só os campos que usamos de formulae.brew.sh/api/cask.json.
struct CaskDTO: Decodable {
    let token: String
    let fullToken: String
    let tap: String
    let name: [String]
    let desc: String?
    let homepage: String?
    let version: String?
    let dependsOnFormulae: [String]
    let caveats: String?
    let deprecated: Bool
    let disabled: Bool

    enum CodingKeys: String, CodingKey {
        case token, tap, name, desc, homepage, version, caveats, deprecated, disabled
        case fullToken = "full_token"
        case dependsOn = "depends_on"
    }

    enum DependsOnKeys: String, CodingKey {
        case formula
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        token = try container.decode(String.self, forKey: .token)
        fullToken = try container.decode(String.self, forKey: .fullToken)
        tap = try container.decode(String.self, forKey: .tap)
        name = (try? container.decode([String].self, forKey: .name)) ?? []
        desc = try? container.decode(String.self, forKey: .desc)
        homepage = try? container.decode(String.self, forKey: .homepage)
        version = try? container.decode(String.self, forKey: .version)
        caveats = try? container.decode(String.self, forKey: .caveats)
        deprecated = (try? container.decode(Bool.self, forKey: .deprecated)) ?? false
        disabled = (try? container.decode(Bool.self, forKey: .disabled)) ?? false

        if let dependsOn = try? container.nestedContainer(keyedBy: DependsOnKeys.self, forKey: .dependsOn) {
            dependsOnFormulae = (try? dependsOn.decode([String].self, forKey: .formula)) ?? []
        } else {
            dependsOnFormulae = []
        }
    }
}

// Saída de `brew outdated --json=v2`
struct OutdatedReportDTO: Decodable {
    let formulae: [OutdatedItem]
    let casks: [OutdatedItem]

    struct OutdatedItem: Decodable {
        let name: String
        let installedVersions: [String]

        enum CodingKeys: String, CodingKey {
            case name
            case installedVersions = "installed_versions"
        }
    }
}
