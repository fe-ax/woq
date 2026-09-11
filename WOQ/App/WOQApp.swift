import SwiftData
import SwiftUI
import UIKit
import os

@main
struct WOQApp: App {
    private let container: ModelContainer
    @State private var store: QueueStore
    /// The folder Marco picks once in Files; nil until he does (WOQ/Backup/BackupFolder.swift).
    @State private var backupFolder: BackupFolder
    /// Debounced automatic backups. One instance for the whole app, fed by `store.onSaved`.
    @State private var backupScheduler: BackupScheduler

    @Environment(\.scenePhase) private var scenePhase

    /// Menu > Appearance. `system` (the default) leaves the theme to the iPhone
    /// (AppSettings.swift).
    @AppStorage(AppSettings.appearanceKey) private var appearanceRaw = Appearance.system.rawValue

    private var appearance: Appearance { Appearance(rawValue: appearanceRaw) ?? .system }

    init() {
        let container = WOQApp.makeContainer()
        self.container = container

        let store = QueueStore(modelContext: container.mainContext)
        let folder = BackupFolder()
        let scheduler = BackupScheduler(context: container.mainContext, folder: folder)
        // Every successful save restarts the 3-second debounce; weak so the closure the store
        // holds forever cannot keep a dead scheduler alive.
        store.onSaved = { [weak scheduler] in scheduler?.noteChange() }

        _store = State(initialValue: store)
        _backupFolder = State(initialValue: folder)
        _backupScheduler = State(initialValue: scheduler)
    }

    var body: some Scene {
        WindowGroup {
            rootView
                .modelContainer(container)
                .environment(store)
                .environment(backupFolder)
                .environment(backupScheduler)
                // The theme is applied to the UIWindow, not with
                // `.preferredColorScheme` — see `applyInterfaceStyle`.
                .onChange(of: appearanceRaw, initial: true) { _, _ in
                    WOQApp.applyInterfaceStyle(appearance)
                }
        }
        // iOS may suspend the process before the debounce task wakes up, so flush a pending
        // backup synchronously on the way out (BackupScheduler.backupNowIfNeeded()).
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                backupScheduler.backupNowIfNeeded()
            }
            // A window that appeared later (or after a cold-launch race) still
            // gets the chosen theme.
            if phase == .active {
                WOQApp.applyInterfaceStyle(appearance)
            }
        }
    }

    // MARK: - Appearance

    /// Applies menu > Appearance to every window of the scene.
    ///
    /// `.preferredColorScheme(appearance.colorScheme)` on the root view was the
    /// first attempt and does theme the main screen (verified 2026-09-05), but
    /// it pins an *already presented* sheet to the scheme it was presented with:
    /// with the phone in dark mode and the app set to Dark, switching to Light
    /// inside the menu turned the screen behind the sheet light while the sheet
    /// itself stayed dark. Overriding the window instead has no such pin — the
    /// root, every sheet, the alerts and even the system file picker follow the
    /// change live, in both directions (all verified on the simulator).
    ///
    /// `.unspecified` hands the choice back to the iPhone, which is exactly what
    /// `Appearance.system` means.
    private static func applyInterfaceStyle(_ appearance: Appearance) {
        let style: UIUserInterfaceStyle =
            switch appearance {
            case .system: .unspecified
            case .light: .light
            case .dark: .dark
            }

        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for window in windowScene.windows {
                window.overrideUserInterfaceStyle = style
            }
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
    /// The schema is the current versioned one (`WOQSchemaV2`, see Schema.swift) and is passed
    /// together with `WOQMigrationPlan`, which carries the V1 -> V2 lightweight stage — so a
    /// store seeded by the V1 build opens and migrates instead of being wiped, and a future
    /// version only has to add another stage there. The configuration gets the *same* `Schema`
    /// instance as the container.
    private static func makeContainer() -> ModelContainer {
        let schema = Schema(versionedSchema: WOQSchemaV2.self)
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
            if let retried = try? ModelContainer(
                for: schema,
                migrationPlan: WOQMigrationPlan.self,
                configurations: configuration
            ) {
                logger.notice("model container rebuilt after deleting the development store")
                return retried
            }
            #endif

            do {
                logger.error("falling back to an in-memory container: data will not persist")
                return try ModelContainer(
                    for: schema,
                    migrationPlan: WOQMigrationPlan.self,
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
