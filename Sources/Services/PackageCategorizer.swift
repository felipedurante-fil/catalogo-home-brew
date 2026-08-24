import Foundation

enum PackageCategorizer {
    /// Regras ordenadas — a primeira categoria cujas palavras-chave batem no texto vence.
    /// Roda sobre o texto original em inglês (nome+desc+id), antes de qualquer tradução.
    private static let rules: [(PackageCategory, [String])] = [
        (.jogos, ["game", "arcade", "puzzle"]),
        (.seguranca, [
            "security", "encrypt", "vpn", "firewall", "password", "vulnerability",
            "antivirus", "malware", "exploit", "penetration test", "forensic",
        ]),
        (.bancosDeDados, [
            "database", "sql", "postgres", "mysql", "mongodb", "redis", "sqlite", "mariadb",
        ]),
        (.redes, ["network", "proxy", "dns", "ssh", "socket", "packet", "router", "ftp server"]),
        (.multimidia, [
            "video", "audio", "image", "photo", "music", "codec", "camera", "streaming", "media player",
        ]),
        (.ciencia, [
            "machine learning", "data science", "statistic", "bioinformatics",
            "neural network", "scientific comput",
        ]),
        (.desenvolvimento, [
            "compiler", "sdk", "framework", "developer", "debugger", "linter", "build tool",
            "package manager", "docker", "kubernetes", "cli", "command-line", "programming language",
        ]),
        (.produtividade, ["notes", "calendar", "task", "to-do", "pdf", "office", "note-taking"]),
        (.sistema, [
            "menu bar", "backup", "system monitor", "cleaner", "file manager",
            "terminal emulator", "window manager",
        ]),
    ]

    static func category(id: String, name: String, desc: String) -> PackageCategory {
        if id.hasPrefix("font-") || id.contains("/font-") {
            return .fontes
        }

        let haystack = "\(name) \(desc) \(id)".lowercased()
        if haystack.contains("font") || haystack.contains("typeface") {
            return .fontes
        }

        for (category, keywords) in rules {
            if keywords.contains(where: { haystack.contains($0) }) {
                return category
            }
        }

        return .outros
    }
}
