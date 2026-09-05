#if DEBUG
import SwiftData
import SwiftUI

/// Menu page: things that only exist in a DEBUG build. Today just the sample
/// data (WOQ/Model/SeedData.swift); the Release build has no Developer row on
/// the root page at all.
struct DeveloperPage: View {
    /// Called after the samples are inserted, so the sheet can get out of the way.
    var onInserted: () -> Void

    @Environment(QueueStore.self) private var store
    @Environment(\.modelContext) private var modelContext

    @State private var showSeedAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: Tokens.rowSpacing) {
                MenuActionRow(
                    title: String(localized: "Sample data"),
                    subtitle: String(localized: "DEBUG only: adds a handful of exercises with sets"),
                    buttonTitle: String(localized: "Insert")
                ) {
                    showSeedAlert = true
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .scrollEdgeEffectStyle(.hard, for: .top)
        // An alert, not a `confirmationDialog`: iOS 26 draws the dialog without a visible
        // Cancel (TODO.md).
        .alert(Text(verbatim: "Debug"), isPresented: $showSeedAlert) {
            Button(String(localized: "Insert sample data")) {
                withAnimation(.snappy) {
                    SeedData.insertSamples(using: store, context: modelContext)
                }
                onInserted()
            }
            Button(String(localized: "Cancel"), role: .cancel) {}
        }
    }
}
#endif
