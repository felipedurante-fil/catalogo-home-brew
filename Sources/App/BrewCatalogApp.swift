import SwiftUI
import SwiftData

@main
struct BrewCatalogApp: App {
    let container: ModelContainer

    init() {
        do {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appending(path: "BrewCatalog", directoryHint: .isDirectory)
            try FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
            let storeURL = appSupport.appending(path: "BrewCatalog.store")
            let configuration = ModelConfiguration(url: storeURL)
            container = try ModelContainer(for: Package.self, configurations: configuration)
        } catch {
            fatalError("Não foi possível criar o ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
