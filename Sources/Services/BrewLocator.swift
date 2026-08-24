import Foundation

enum BrewLocator {
    private static let candidatePaths = [
        "/opt/homebrew/bin/brew",   // Apple Silicon
        "/usr/local/bin/brew",      // Intel
    ]

    static var brewPath: String? {
        candidatePaths.first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    static var isHomebrewInstalled: Bool { brewPath != nil }
}
