import Foundation
import SwiftData
import Observation

@Observable
final class CatalogViewModel {
    private(set) var isSyncing = false
    private(set) var syncError: String?
    var lastSyncDate: Date? {
        get { UserDefaults.standard.object(forKey: Self.lastSyncKey) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: Self.lastSyncKey) }
    }

    private static let lastSyncKey = "BrewCatalog.lastSyncDate"

    var homebrewMissing: Bool { !BrewLocator.isHomebrewInstalled }

    func syncCatalog(container: ModelContainer) async {
        guard !isSyncing else { return }
        isSyncing = true
        syncError = nil
        do {
            try await CatalogService.sync(container: container)
            lastSyncDate = Date()
        } catch {
            syncError = error.localizedDescription
        }
        isSyncing = false
    }

    func refreshInstalledStatus(context: ModelContext) async {
        do {
            try await InstalledStatusService.refresh(in: context)
        } catch {
            syncError = error.localizedDescription
        }
    }
}
