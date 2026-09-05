import SwiftData
import SwiftUI

/// One page of the app menu. Adding a setting is one case here, one `MenuRow` on
/// the root page and one view under `WOQ/Screens/Menu/` — nothing else knows
/// about the navigation.
nonisolated enum MenuPage: Hashable, Identifiable {
    case appearance
    case backups
    #if DEBUG
    case developer
    #endif

    var id: Self { self }

    /// Title of the pushed page's header bar.
    var title: String {
        switch self {
        case .appearance: String(localized: "Appearance")
        case .backups: String(localized: "Backups")
        #if DEBUG
        case .developer: String(localized: "Developer")
        #endif
        }
    }
}

/// The app's settings surface, opened by long-pressing the "Workout Queue" title.
///
/// A large sheet with a root page of rows and pushed submenus (Appearance,
/// Backups, and in DEBUG Developer). The navigation is hand-rolled — a
/// `[MenuPage]` stack plus an asymmetric move transition — because a
/// `NavigationStack` brings a system navigation bar, and iOS 26 draws that as
/// Liquid Glass (PLAN.md pitfall 7 and 29). The header is the shared
/// `SheetHeaderBar`, with a back chevron in its leading slot once a page is
/// pushed.
///
/// Same paper rules as the other sheets: no `List`/`Form`, only `Tokens`
/// colours and the `.plain` / `.paper` / `.ink` button styles.
struct AppMenuSheet: View {
    /// Forwards a message to `MainScreen`'s hint toast after the sheet closes itself.
    var onHint: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(BackupFolder.self) private var backupFolder
    @Environment(BackupScheduler.self) private var backupScheduler

    /// Only for the summary line under "Appearance" on the root page; the page
    /// itself owns the same two keys (AppSettings.swift).
    @AppStorage(AppSettings.appearanceKey) private var appearanceRaw = Appearance.system.rawValue
    @AppStorage(AppSettings.waterRippleKey) private var waterRipple = true

    /// Empty = root page. A stack rather than a single optional so a page can
    /// push a page later without touching this file's structure.
    @State private var path: [MenuPage] = []
    /// Which way the next transition runs; set right before the animation.
    @State private var isPopping = false

    @State private var showsPicker = false
    @State private var restoreCheckToken = 0
    /// Feedback that belongs inside the sheet (errors, "nothing found"); the toast on
    /// MainScreen would be hidden behind it.
    @State private var message: String?

    var body: some View {
        ZStack {
            Tokens.paper.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                Rectangle()
                    .fill(Tokens.ink)
                    .frame(height: Tokens.hairline)

                pages
            }
        }
        .hintToast($message)
        // Stays on the sheet's root, never on a page: the system folder picker and
        // the restore alert have to survive a pop while they are up.
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
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Tokens.paper)
    }

    // MARK: - Chrome

    private var header: some View {
        SheetHeaderBar(
            title: path.last?.title ?? String(localized: "Workout Queue"),
            leading: {
                if !path.isEmpty {
                    SheetBackButton { pop() }
                }
            },
            trailing: {
                Button(String(localized: "Close")) { dismiss() }
                    .buttonStyle(.ink)
            }
        )
    }

    /// The pages share one slot: during a transition the outgoing and incoming
    /// page overlap here instead of stacking, and the clip keeps them inside the
    /// sheet while they slide.
    private var pages: some View {
        ZStack(alignment: .top) {
            page
                .id(path.last)
                .transition(pageTransition)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .clipped()
    }

    @ViewBuilder
    private var page: some View {
        if let current = path.last {
            switch current {
            case .appearance:
                AppearancePage()
            case .backups:
                BackupsPage(
                    onChooseFolder: { showsPicker = true },
                    onRestore: { restoreCheckToken += 1 }
                )
            #if DEBUG
            case .developer:
                DeveloperPage { dismiss() }
            #endif
            }
        } else {
            rootPage
        }
    }

    // MARK: - Root

    private var rootPage: some View {
        ScrollView {
            VStack(spacing: Tokens.rowSpacing) {
                MenuRow(
                    title: MenuPage.appearance.title,
                    subtitle: AppearancePage.summary(
                        appearanceRaw: appearanceRaw,
                        waterRipple: waterRipple
                    )
                ) {
                    push(.appearance)
                }

                MenuRow(
                    title: MenuPage.backups.title,
                    subtitle: BackupsPage.summary(
                        folder: backupFolder,
                        scheduler: backupScheduler
                    )
                ) {
                    push(.backups)
                }

                #if DEBUG
                MenuRow(
                    title: MenuPage.developer.title,
                    subtitle: String(localized: "Sample data")
                ) {
                    push(.developer)
                }
                #endif
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .scrollEdgeEffectStyle(.hard, for: .top)
    }

    // MARK: - Navigation

    /// Push: the new page comes in from the trailing edge, the old one leaves to
    /// the leading edge. Pop mirrors it. `isPopping` is set before the animation
    /// so the transition is already pointing the right way when the body runs.
    private var pageTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: isPopping ? .leading : .trailing).combined(with: .opacity),
            removal: .move(edge: isPopping ? .trailing : .leading).combined(with: .opacity)
        )
    }

    private func push(_ page: MenuPage) {
        isPopping = false
        withAnimation(.snappy) { path.append(page) }
    }

    private func pop() {
        isPopping = true
        withAnimation(.snappy) { _ = path.popLast() }
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
