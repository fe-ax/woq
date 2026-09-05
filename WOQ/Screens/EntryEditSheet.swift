import SwiftUI

/// Edit weight and reps (not the date) of one logged entry. INTERFACE CONTRACT fixed by the orchestrator;
/// the sheets agent replaces the body. Presented from ExerciseDetailSheet's history list.
struct EntryEditSheet: View {
    var entry: Entry
    var isUnilateral: Bool

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        // STUB — replaced in wave 3.
        VStack(spacing: 16) {
            Text("Entry edit (stub)")
                .foregroundStyle(Tokens.ink)
            Button(String(localized: "Close")) { dismiss() }
                .buttonStyle(.paper)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Tokens.paper.ignoresSafeArea())
    }
}
