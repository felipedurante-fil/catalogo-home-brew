import Foundation
import SwiftData

enum InstalledStatusService {
    /// Roda `brew list --formula/--cask -1` e `brew outdated --json=v2`, e atualiza
    /// isInstalled/isOutdated/installedVersion em todos os Package do contexto.
    static func refresh(in context: ModelContext) async throws {
        guard let brewPath = BrewLocator.brewPath else { return }

        async let installedFormulae = runList(brewPath: brewPath, arguments: ["list", "--formula", "-1"])
        async let installedCasks = runList(brewPath: brewPath, arguments: ["list", "--cask", "-1"])
        async let outdated = runOutdated(brewPath: brewPath)

        let (formulaeNames, caskNames, outdatedReport) = try await (installedFormulae, installedCasks, outdated)

        let outdatedFormulaeVersions = Dictionary(
            uniqueKeysWithValues: outdatedReport?.formulae.map { ($0.name, $0.installedVersions.last ?? "") } ?? []
        )
        let outdatedCaskVersions = Dictionary(
            uniqueKeysWithValues: outdatedReport?.casks.map { ($0.name, $0.installedVersions.last ?? "") } ?? []
        )

        let installedFormulaeSet = Set(formulaeNames)
        let installedCaskSet = Set(caskNames)

        let descriptor = FetchDescriptor<Package>()
        let packages = try context.fetch(descriptor)

        for package in packages {
            switch package.kind {
            case .formula:
                let shortName = package.id.components(separatedBy: "/").last ?? package.id
                package.isInstalled = installedFormulaeSet.contains(shortName) || installedFormulaeSet.contains(package.id)
                if let outdatedVersion = outdatedFormulaeVersions[shortName] ?? outdatedFormulaeVersions[package.id] {
                    package.isOutdated = true
                    package.installedVersion = outdatedVersion
                } else {
                    package.isOutdated = false
                    package.installedVersion = package.isInstalled ? package.version : nil
                }
            case .cask:
                package.isInstalled = installedCaskSet.contains(package.id)
                if let outdatedVersion = outdatedCaskVersions[package.id] {
                    package.isOutdated = true
                    package.installedVersion = outdatedVersion
                } else {
                    package.isOutdated = false
                    package.installedVersion = package.isInstalled ? package.version : nil
                }
            }
        }

        try context.save()
    }

    private static func runList(brewPath: String, arguments: [String]) async throws -> [String] {
        let output = try await runCapturingOutput(brewPath: brewPath, arguments: arguments)
        return output
            .split(separator: "\n")
            .map { String($0).trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    private static func runOutdated(brewPath: String) async throws -> OutdatedReportDTO? {
        let output = try await runCapturingOutput(brewPath: brewPath, arguments: ["outdated", "--json=v2"])
        guard let data = output.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(OutdatedReportDTO.self, from: data)
    }

    private static func runCapturingOutput(brewPath: String, arguments: [String]) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: brewPath)
            process.arguments = arguments

            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = Pipe() // descarta stderr, não nos interessa aqui

            process.terminationHandler = { _ in
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let text = String(data: data, encoding: .utf8) ?? ""
                continuation.resume(returning: text)
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
