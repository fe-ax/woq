import SwiftData
import SwiftUI
import os

@main
struct WOQApp: App {
    private let container: ModelContainer
    @State private var store: QueueStore

    init() {
        let container = WOQApp.makeContainer()
        self.container = container
        _store = State(initialValue: QueueStore(modelContext: container.mainContext))
    }

    var body: some Scene {
        WindowGroup {
            MainScreen()
                .preferredColorScheme(.light)
                .modelContainer(container)
                .environment(store)
        }
    }

    // MARK: - Container

    private static let logger = Logger(subsystem: "nl.feax.woq", category: "app")

    /// Builds the on-disk container. A schema change during development throws
    /// `loadIssueModelContainer` (PLAN.md pitfall 27): in DEBUG the store files are deleted
    /// and the container is built once more, in Release the app falls back to an in-memory
    /// container and logs, so it still launches instead of crashing.
    private static func makeContainer() -> ModelContainer {
        let schema = Schema([Exercise.self, Entry.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            logger.error("model container failed: \(error.localizedDescription, privacy: .public)")

            #if DEBUG
            deleteStoreFiles()
            if let retried = try? ModelContainer(for: schema, configurations: configuration) {
                logger.notice("model container rebuilt after deleting the development store")
                return retried
            }
            #endif

            do {
                logger.error("falling back to an in-memory container: data will not persist")
                return try ModelContainer(
                    for: schema,
                    configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                )
            } catch {
                fatalError("Could not create any ModelContainer: \(error)")
            }
        }
    }

    #if DEBUG
    /// Removes `default.store`, `-wal` and `-shm` from Application Support. DEBUG only:
    /// during development a schema change is fixed by throwing the store away, never by a
    /// migration (PLAN.md pitfall 12).
    private static func deleteStoreFiles() {
        let directory = URL.applicationSupportDirectory
        for name in ["default.store", "default.store-wal", "default.store-shm"] {
            let url = directory.appending(path: name)
            do {
                if FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) {
                    try FileManager.default.removeItem(at: url)
                    logger.notice("deleted development store file \(name, privacy: .public)")
                }
            } catch {
                logger.error(
                    "could not delete \(name, privacy: .public): \(error.localizedDescription, privacy: .public)"
                )
            }
        }
    }
    #endif
}
