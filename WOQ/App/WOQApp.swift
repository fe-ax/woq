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
            rootView
                .preferredColorScheme(.light)
                .modelContainer(container)
                .environment(store)
        }
    }

    /// DEBUG: `xcrun simctl launch <sim> nl.feax.woq --gallery` opens the component gallery instead of the app.
    @ViewBuilder
    private var rootView: some View {
        #if DEBUG
        if CommandLine.arguments.contains("--gallery") {
            ComponentGallery()
        } else if let index = CommandLine.arguments.firstIndex(of: "--preview"),
                  index + 1 < CommandLine.arguments.count {
            // `--preview add|edit|detail|entry` shows one sheet's content as the root (see DebugPreviews.swift).
            DebugPreviewRoot(name: CommandLine.arguments[index + 1])
        } else {
            MainScreen()
        }
        #else
        MainScreen()
        #endif
    }

    // MARK: - Container

    private static let logger = Logger(subsystem: "nl.feax.woq", category: "app")

    /// Builds the on-disk container. A schema change during development throws
    /// `loadIssueModelContainer` (PLAN.md pitfall 27): in DEBUG the store files are deleted
    /// and the container is built once more, in Release the app falls back to an in-memory
    /// container and logs, so it still launches instead of crashing.
    ///
    /// The schema is the versioned one (`WOQSchemaV1`, see Schema.swift) and is passed together
    /// with `WOQMigrationPlan`, so a future version only has to add a stage there instead of
    /// wiping real data. The configuration gets the *same* `Schema` instance as the container.
    private static func makeContainer() -> ModelContainer {
        let schema = Schema(versionedSchema: WOQSchemaV1.self)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(
                for: schema,
                migrationPlan: WOQMigrationPlan.self,
                configurations: configuration
            )
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
