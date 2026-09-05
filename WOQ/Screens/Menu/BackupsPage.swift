import SwiftUI

/// Menu page: the three backup rows, moved here unchanged from the old flat
/// menu sheet.
///
/// PLAN.md section 2 "Backups": backups run automatically and silently, so this
/// page only has to let Marco pick the folder once, see that it is working, and
/// restore after a reinstall.
///
/// The `.fileImporter` and the restore alert live on the sheet's root view
/// (`AppMenuSheet` + `BackupSetupFlow`), not here: a page can be popped while
/// the system picker is up, and the modifier must survive that. This view only
/// asks for them through `onChooseFolder` / `onRestore`.
struct BackupsPage: View {
    var onChooseFolder: () -> Void
    var onRestore: () -> Void

    @Environment(BackupFolder.self) private var backupFolder
    @Environment(BackupScheduler.self) private var backupScheduler

    var body: some View {
        ScrollView {
            VStack(spacing: Tokens.rowSpacing) {
                folderRow
                lastBackupRow
                restoreRow
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .scrollEdgeEffectStyle(.hard, for: .top)
    }

    // MARK: - Rows

    private var folderRow: some View {
        MenuActionRow(
            title: String(localized: "Backup folder"),
            subtitle: BackupsPage.folderName(backupFolder) ?? String(localized: "Not set"),
            detail: backupFolder.lastError,
            buttonTitle: backupFolder.url == nil
                ? String(localized: "Choose…")
                : String(localized: "Change…"),
            action: onChooseFolder
        )
    }

    private var lastBackupRow: some View {
        MenuActionRow(
            title: String(localized: "Last backup"),
            subtitle: backupScheduler.lastBackupAt.map(Formatting.absoluteDateTimeString)
                ?? String(localized: "Never"),
            detail: backupScheduler.lastError,
            buttonTitle: String(localized: "Back up now")
        ) {
            backupScheduler.performBackup()
        }
    }

    private var restoreRow: some View {
        MenuActionRow(
            title: String(localized: "Restore"),
            subtitle: String(localized: "Merges the backup in the chosen folder into this device"),
            buttonTitle: String(localized: "Restore…"),
            isDisabled: backupFolder.url == nil,
            action: onRestore
        )
    }

    // MARK: - Helpers

    /// Just the folder's own name; the full path of a provider URL is unreadable noise.
    static func folderName(_ folder: BackupFolder) -> String? {
        folder.url?.lastPathComponent.removingPercentEncoding
            ?? folder.url?.lastPathComponent
    }

    /// One-line summary for the row on the root page: the folder, plus the time
    /// of the last backup when there is one.
    static func summary(folder: BackupFolder, scheduler: BackupScheduler) -> String {
        let where_ = folderName(folder) ?? String(localized: "No folder yet")
        guard let last = scheduler.lastBackupAt else { return where_ }
        let when = Formatting.absoluteDateTimeString(last)
        return "\(where_) · \(String(localized: "Last backup \(when)"))"
    }
}
