import SwiftUI

/// Long-press detail sheet: large figures, muscles, history (edit/delete entries), Edit and Delete exercise.
/// INTERFACE CONTRACT fixed by the orchestrator; the sheets agent replaces the body.
/// Presented by MainScreen via `.sheet(item:)` with the tapped `Exercise`.
struct ExerciseDetailSheet: View {
    var exercise: Exercise

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        // STUB — replaced in wave 3.
        VStack(spacing: 16) {
            Text("Detail (stub): \(exercise.name)")
                .foregroundStyle(Tokens.ink)
            Button(String(localized: "Close")) { dismiss() }
                .buttonStyle(.paper)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Tokens.paper.ignoresSafeArea())
    }
}
