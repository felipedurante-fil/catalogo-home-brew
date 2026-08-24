import Foundation
import Observation

enum BrewCommandError: Error {
    case brewNotFound
}

@Observable
final class BrewCommandRunner {
    private(set) var isRunning = false
    private(set) var log: String = ""
    private(set) var exitCode: Int32?

    private var process: Process?

    /// Roda `brew <arguments>` e publica cada linha de saída em `log` conforme chega.
    func run(_ arguments: [String]) throws {
        guard let brewPath = BrewLocator.brewPath else {
            throw BrewCommandError.brewNotFound
        }

        log = ""
        exitCode = nil
        isRunning = true

        let process = Process()
        process.executableURL = URL(fileURLWithPath: brewPath)
        process.arguments = arguments

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let chunk = String(data: data, encoding: .utf8) else { return }
            DispatchQueue.main.async {
                self?.log += chunk
            }
        }

        process.terminationHandler = { [weak self] finished in
            pipe.fileHandleForReading.readabilityHandler = nil
            DispatchQueue.main.async {
                self?.isRunning = false
                self?.exitCode = finished.terminationStatus
            }
        }

        self.process = process
        try process.run()
    }

    func cancel() {
        process?.terminate()
    }
}
