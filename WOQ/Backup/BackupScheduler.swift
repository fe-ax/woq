import Foundation
import SwiftData
import os

/// Runs backups by itself, so Marco never has to think about them.
///
/// Wiring (done by the UI step): create one scheduler next to `QueueStore`, set
/// `store.onSaved = { [weak scheduler] in scheduler?.noteChange() }`, and call
/// `backupNowIfNeeded()` when `scenePhase` becomes `.background`.
///
/// Timing: every save nudges `noteChange()`, which restarts a 3-second debounce. A burst of
/// edits (finalize a set, fix the reps, delete an entry) therefore produces exactly one file
/// write, three seconds after the last change. Sending the app to the background flushes a
/// pending debounce immediately, so nothing is lost when iOS suspends the process.
///
/// Failure policy: a backup must never take the app down or block the UI. Every error is
/// logged to `os.Logger(subsystem: "nl.feax.woq", category: "backup")` and surfaced through
/// `lastError`; a missing, moved or offline external folder is a logged non-event and the
/// local copy still gets written.
///
/// Concurrency: `@MainActor` throughout, no `Task.detached`, no background `ModelContext`
/// (PLAN.md pitfall 13 and 25). The only `Task` is the debounce timer and it does no work of
/// its own beyond sleeping.
@MainActor @Observable final class BackupScheduler {

    /// When the last backup succeeded (at least the local copy), or nil when none ran yet.
    private(set) var lastBackupAt: Date?

    /// Last failure, cleared by the next success. nil = healthy.
    private(set) var lastError: String?

    /// True while a debounced backup is waiting to fire; lets the UI show "saving…".
    var isPending: Bool { pendingTask != nil }

    @ObservationIgnored private let context: ModelContext
    @ObservationIgnored private let folder: BackupFolder
    @ObservationIgnored private let debounceInterval: Duration
    @ObservationIgnored private let keepDailySnapshots: Int
    @ObservationIgnored private var pendingTask: Task<Void, Never>?
    @ObservationIgnored private let logger = Logger(subsystem: "nl.feax.woq", category: "backup")

    /// - Parameters:
    ///   - context: the main context (`container.mainContext`), the same one `QueueStore` uses.
    ///   - folder: the external destination; local backups run even when it is empty.
    ///   - debounceInterval: quiet period after the last change. 3 seconds per the spec.
    ///   - keepDailySnapshots: dated snapshots to keep per folder.
    init(
        context: ModelContext,
        folder: BackupFolder,
        debounceInterval: Duration = .seconds(3),
        keepDailySnapshots: Int = 14
    ) {
        self.context = context
        self.folder = folder
        self.debounceInterval = debounceInterval
        self.keepDailySnapshots = keepDailySnapshots
        // So a relaunch shows the real "last backup" instead of "never".
        self.lastBackupAt = Self.modificationDate(
            of: BackupFolder.localDirectory.appending(path: BackupDocument.fileName)
        )
    }

    deinit {
        pendingTask?.cancel()
    }

    // MARK: - Triggers

    /// Something changed in the store. Restarts the debounce; cheap to call on every save.
    func noteChange() {
        pendingTask?.cancel()
        pendingTask = Task { [weak self, debounceInterval] in
            do {
                try await Task.sleep(for: debounceInterval)
            } catch {
                return // cancelled by a newer change or by backupNowIfNeeded()
            }
            guard !Task.isCancelled, let self else { return }
            self.pendingTask = nil
            self.performBackup()
        }
    }

    /// Flushes a pending debounce right now. Call this when `scenePhase` becomes `.background`
    /// (and from `.willTerminate` if that is ever wired): iOS may suspend the process before a
    /// sleeping `Task` wakes up, so the pending write has to happen synchronously here.
    /// Does nothing when no change is waiting, so backgrounding the app repeatedly does not
    /// rewrite an unchanged file.
    func backupNowIfNeeded() {
        guard pendingTask != nil else { return }
        performBackup()
    }

    // MARK: - The backup itself

    /// Builds the document once and writes it to the local folder and, when configured, to
    /// the external one. Never throws: everything ends up in `lastError` and the log.
    func performBackup() {
        pendingTask?.cancel()
        pendingTask = nil

        let document: BackupDocument
        do {
            document = try BackupWriter.makeDocument(context: context)
        } catch {
            report(error, while: "reading the store")
            return
        }

        var failure: String?
        var localWritten = false

        do {
            try BackupWriter.write(
                document,
                to: BackupFolder.localDirectory,
                keepDailySnapshots: keepDailySnapshots
            )
            localWritten = true
        } catch {
            failure = error.localizedDescription
            logger.error("local backup failed: \(error.localizedDescription, privacy: .public)")
        }

        // A folder that was never picked is the normal case, not a failure. A folder that was
        // picked but is gone (deleted, iCloud signed out, provider offline) is logged and
        // skipped: the local copy above is what keeps the data safe until it comes back.
        if folder.url != nil {
            do {
                try folder.withAccess { external in
                    try BackupWriter.write(document, to: external, keepDailySnapshots: keepDailySnapshots)
                }
            } catch {
                failure = error.localizedDescription
                logger.error("external backup failed: \(error.localizedDescription, privacy: .public)")
            }
        }

        if localWritten {
            lastBackupAt = .now
            logger.info(
                "backup written: \(document.exercises.count, privacy: .public) exercises, \(document.entryCount, privacy: .public) sets"
            )
        }
        lastError = failure
    }

    // MARK: - Helpers

    private func report(_ error: Error, while activity: String) {
        logger.error("backup failed while \(activity, privacy: .public): \(error.localizedDescription, privacy: .public)")
        lastError = error.localizedDescription
    }

    private static func modificationDate(of url: URL) -> Date? {
        try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
    }
}
