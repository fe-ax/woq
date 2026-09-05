import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// One-time nudge under the search field: "pick a folder in Files and I will keep it up to
/// date". PLAN.md section 2 "Backups": backups are automatic and silent, so the only piece of
/// UI Marco ever has to touch is this card (and the same two actions in `AppMenuSheet`).
///
/// Shown only when no folder is configured, there is something to lose (at least one
/// exercise), and it was not snoozed in the last `snoozeDays` days.
struct BackupBanner: View {
    var onChoose: () -> Void
    var onLater: () -> Void

    var body: some View {
        OutlinedCard(showsShadow: true) {
            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "Back up automatically"))
                    .font(.system(.body, weight: .semibold))
                    .foregroundStyle(Tokens.ink)

                Text(String(localized: "Pick a folder in Files (for example iCloud Drive) and every change is saved there."))
                    .font(.subheadline)
                    .foregroundStyle(Tokens.muted)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    Button(String(localized: "Choose folder"), action: onChoose)
                        .buttonStyle(.ink)
                    Button(String(localized: "Later"), action: onLater)
                        .buttonStyle(.paper)
                    Spacer(minLength: 0)
                }
                .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: - Snoozing

    /// `UserDefaults` key holding the moment "Later" was tapped.
    static let dismissedAtKey = "backupBannerDismissedAt"
    /// How long "Later" hides the banner.
    static let snoozeDays = 7

    /// True while the banner is snoozed. `now` is injectable for previews and debugging.
    static func isSnoozed(_ now: Date = .now, defaults: UserDefaults = .standard) -> Bool {
        guard let dismissed = defaults.object(forKey: dismissedAtKey) as? Date else { return false }
        guard let expiry = Calendar.current.date(byAdding: .day, value: snoozeDays, to: dismissed) else {
            return false
        }
        return now < expiry
    }

    /// Records "Later". The banner comes back after `snoozeDays`.
    static func snooze(_ now: Date = .now, defaults: UserDefaults = .standard) {
        defaults.set(now, forKey: dismissedAtKey)
    }
}

// MARK: - Shared folder-picking and restore flow

/// The "choose a folder, then offer to restore what is already in it" flow, shared by the
/// banner on `MainScreen` and the rows in `AppMenuSheet` so both behave identically.
///
/// Sequence:
/// 1. `showsPicker` opens `.fileImporter` limited to folders.
/// 2. The chosen URL goes to `BackupFolder.set(_:)`, which turns it into a bookmark while the
///    picker's grant is still live.
/// 3. The folder is **read before anything is written**. When it already holds a
///    `woq-backup.json` — the reinstall case — an alert offers to merge it into this device;
///    the merge is additive and idempotent (`BackupImporter`), and the backup that follows it
///    then contains everything. When the folder holds nothing, the first backup is written
///    straight away so Marco sees the file appear.
///
///    The read has to come first: `BackupWriter.write` replaces `woq-backup.json`
///    unconditionally, so backing up an empty freshly-installed store before reading would
///    destroy exactly the file the restore needs. Cancelling the alert therefore writes
///    nothing either — the first real change starts the normal debounced backup.
///
/// Bumping `restoreCheckToken` runs the check on its own, which is what the menu's "Restore…"
/// button does; that path reports an empty folder instead of silently writing to it.
struct BackupSetupFlow: ViewModifier {
    @Binding var showsPicker: Bool
    @Binding var restoreCheckToken: Int
    /// Problems worth showing: "nothing found in this folder", a picker or bookmark error.
    var onMessage: (String) -> Void
    /// Called with the merge summary after a successful restore (the menu sheet also closes).
    var onRestored: (String) -> Void

    @Environment(BackupFolder.self) private var backupFolder
    @Environment(BackupScheduler.self) private var backupScheduler
    @Environment(\.modelContext) private var modelContext

    @State private var candidate: BackupDocument?
    @State private var showRestoreAlert = false

    func body(content: Content) -> some View {
        content
            .fileImporter(
                isPresented: $showsPicker,
                allowedContentTypes: [.folder],
                allowsMultipleSelection: false,
                onCompletion: handlePick
            )
            .onChange(of: restoreCheckToken) { _, _ in
                checkForRestore(announcingEmptyFolder: true)
            }
            .alert(
                String(localized: "Restore backup?"),
                isPresented: $showRestoreAlert,
                presenting: candidate
            ) { document in
                Button(String(localized: "Restore")) { restore(document) }
                Button(String(localized: "Cancel"), role: .cancel) {}
            } message: { document in
                Text(Self.restoreMessage(for: document))
            }
    }

    // MARK: - Steps

    private func handlePick(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            do {
                try backupFolder.set(url)
                checkForRestore(announcingEmptyFolder: false)
            } catch {
                onMessage(error.localizedDescription)
            }
        case .failure(let error):
            onMessage(error.localizedDescription)
        }
    }

    /// Looks for a backup in the configured folder and raises the alert when there is one.
    ///
    /// An empty folder is a question for "Restore…" (`announcingEmptyFolder`) and a plain
    /// fact right after picking one, where it just means "start backing up here".
    private func checkForRestore(announcingEmptyFolder: Bool) {
        guard backupFolder.url != nil else { return }
        do {
            // `withAccess` returns nil when no folder is set and `load` returns nil when the
            // folder holds no file, hence the double optional.
            let document = try backupFolder.withAccess { try BackupImporter.load(from: $0) } ?? nil
            if let document {
                candidate = document
                showRestoreAlert = true
            } else if announcingEmptyFolder {
                onMessage(String(localized: "No backup found in this folder"))
            } else {
                backupScheduler.performBackup()
            }
        } catch {
            onMessage(error.localizedDescription)
        }
    }

    private func restore(_ document: BackupDocument) {
        do {
            let summary = try withAnimation(.snappy) {
                try BackupImporter.merge(document, into: modelContext)
            }
            // The merge saves through the context itself, so `QueueStore.onSaved` never fires:
            // nudge the scheduler by hand so the restored data is backed up again.
            backupScheduler.noteChange()
            onRestored(summary.description)
        } catch {
            onMessage(error.localizedDescription)
        }
    }

    static func restoreMessage(for document: BackupDocument) -> String {
        let exercises = document.exercises.count
        let sets = document.entryCount
        let when = Formatting.absoluteDateTimeString(document.exportedAt)
        return String(
            localized: "\(exercises) exercises and \(sets) sets from \(when). Existing data is kept and merged."
        )
    }
}

extension View {
    /// Attaches the shared folder picker and restore prompt (see `BackupSetupFlow`).
    func backupSetupFlow(
        showsPicker: Binding<Bool>,
        restoreCheckToken: Binding<Int>,
        onMessage: @escaping (String) -> Void,
        onRestored: @escaping (String) -> Void
    ) -> some View {
        modifier(
            BackupSetupFlow(
                showsPicker: showsPicker,
                restoreCheckToken: restoreCheckToken,
                onMessage: onMessage,
                onRestored: onRestored
            )
        )
    }
}

#Preview {
    ZStack {
        Tokens.paper.ignoresSafeArea()
        BackupBanner(onChoose: {}, onLater: {})
            .padding(16)
    }
}
