import SwiftData
import SwiftUI

/// The app's only settings surface, opened by long-pressing the "Workout Queue" title.
///
/// PLAN.md section 2 "Backups": backups run automatically and silently, so this sheet is
/// deliberately tiny — pick the folder once, see that it is working, and restore after a
/// reinstall. There is no export/import feature and no general settings screen.
///
/// Same paper rules as the other sheets (PLAN.md pitfall 7 and 29): no system navigation bar,
/// no `List`/`Form`, only `Tokens` colours and the `.paper` / `.ink` button styles.
struct AppMenuSheet: View {
    /// Forwards a message to `MainScreen`'s hint toast after the sheet closes itself.
    var onHint: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(BackupFolder.self) private var backupFolder
    @Environment(BackupScheduler.self) private var backupScheduler

    @State private var showsPicker = false
    @State private var restoreCheckToken = 0
    /// Feedback that belongs inside the sheet (errors, "nothing found"); the toast on
    /// MainScreen would be hidden behind it.
    @State private var message: String?

    #if DEBUG
    @Environment(QueueStore.self) private var store
    @State private var showSeedAlert = false
    #endif

    var body: some View {
        ZStack {
            Tokens.paper.ignoresSafeArea()

            VStack(spacing: 0) {
                SheetHeaderBar(title: String(localized: "Workout Queue")) {
                    Button(String(localized: "Close")) { dismiss() }
                        .buttonStyle(.ink)
                }

                Rectangle()
                    .fill(Tokens.ink)
                    .frame(height: Tokens.hairline)

                ScrollView {
                    VStack(spacing: Tokens.rowSpacing) {
                        folderRow
                        lastBackupRow
                        restoreRow
                        #if DEBUG
                        seedRow
                        #endif
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                }
                .scrollEdgeEffectStyle(.hard, for: .top)
            }
        }
        .hintToast($message)
        .backupSetupFlow(
            showsPicker: $showsPicker,
            restoreCheckToken: $restoreCheckToken,
            onMessage: { message = $0 },
            onRestored: { summary in
                // Hand the merge summary to MainScreen and get out of the way, so the
                // restored queue is what Marco sees next.
                onHint(summary)
                dismiss()
            }
        )
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationBackground(Tokens.paper)
    }

    // MARK: - Rows

    private var folderRow: some View {
        row(
            title: String(localized: "Backup folder"),
            subtitle: folderName ?? String(localized: "Not set"),
            detail: backupFolder.lastError,
            buttonTitle: backupFolder.url == nil
                ? String(localized: "Choose…")
                : String(localized: "Change…")
        ) {
            showsPicker = true
        }
    }

    private var lastBackupRow: some View {
        row(
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
        row(
            title: String(localized: "Restore"),
            subtitle: String(localized: "Merges the backup in the chosen folder into this device"),
            buttonTitle: String(localized: "Restore…"),
            isDisabled: backupFolder.url == nil
        ) {
            restoreCheckToken += 1
        }
    }

    #if DEBUG
    private var seedRow: some View {
        row(
            title: String(localized: "Sample data"),
            subtitle: String(localized: "DEBUG only: adds a handful of exercises with sets"),
            buttonTitle: String(localized: "Insert")
        ) {
            showSeedAlert = true
        }
        // An alert, not a `confirmationDialog`: iOS 26 draws the dialog without a visible
        // Cancel (TODO.md).
        .alert(Text(verbatim: "Debug"), isPresented: $showSeedAlert) {
            Button(String(localized: "Insert sample data")) {
                withAnimation(.snappy) {
                    SeedData.insertSamples(using: store, context: modelContext)
                }
                dismiss()
            }
            Button(String(localized: "Cancel"), role: .cancel) {}
        }
    }
    #endif

    /// One outlined row: title, subtitle, optional error line, trailing paper button.
    private func row(
        title: String,
        subtitle: String,
        detail: String? = nil,
        buttonTitle: String,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        OutlinedCard {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(.body, weight: .semibold))
                        .foregroundStyle(Tokens.ink)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Tokens.muted)
                        .fixedSize(horizontal: false, vertical: true)

                    if let detail {
                        Text(detail)
                            .font(.caption)
                            .foregroundStyle(Tokens.danger)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Button(buttonTitle, action: action)
                    .buttonStyle(.paper)
                    .disabled(isDisabled)
                    .opacity(isDisabled ? 0.4 : 1)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
    }

    // MARK: - Helpers

    /// Just the folder's own name; the full path of a provider URL is unreadable noise.
    private var folderName: String? {
        backupFolder.url?.lastPathComponent.removingPercentEncoding
            ?? backupFolder.url?.lastPathComponent
    }
}

#Preview {
    let container = try! ModelContainer(
        for: Exercise.self, Entry.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let folder = BackupFolder()

    return ZStack { Tokens.paper.ignoresSafeArea() }
        .sheet(isPresented: .constant(true)) {
            AppMenuSheet(onHint: { _ in })
                .modelContainer(container)
                .environment(QueueStore(modelContext: container.mainContext))
                .environment(folder)
                .environment(BackupScheduler(context: container.mainContext, folder: folder))
        }
}
