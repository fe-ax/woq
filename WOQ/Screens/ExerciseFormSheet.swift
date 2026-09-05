import SwiftUI

/// Add / edit an exercise. INTERFACE CONTRACT fixed by the orchestrator; the sheets agent replaces the body.
/// - `.add`: name, unilateral toggle, muscle chips with live figure, optional first set; Save calls
///   `store.addExercise(...)` and then `onAdded` with the result so MainScreen can carry a partial draft
///   into the in-progress card when the outcome is `.startedInProgress`.
/// - `.edit(exercise)`: same fields without the first-set section; Save calls `store.updateExercise(...)`.
struct ExerciseFormSheet: View {
    enum Mode {
        case add
        case edit(Exercise)
    }

    struct AddResult {
        let exercise: Exercise
        let outcome: QueueStore.FirstSetOutcome
        let draft: SetDraft
    }

    var mode: Mode
    var onAdded: ((AddResult) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        // STUB — replaced in wave 3.
        VStack(spacing: 16) {
            Text("Exercise form (stub)")
                .foregroundStyle(Tokens.ink)
            Button(String(localized: "Close")) { dismiss() }
                .buttonStyle(.paper)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Tokens.paper.ignoresSafeArea())
    }
}
