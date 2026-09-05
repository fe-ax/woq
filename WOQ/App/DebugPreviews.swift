import SwiftData
import SwiftUI

#if DEBUG
/// DEBUG root used by `xcrun simctl launch <sim> nl.feax.woq --preview <name>` to show one sheet's content
/// full-screen for visual verification without going through MainScreen. Owned by the sheets agent in wave 3.
/// Names: "add" (ExerciseFormSheet .add), "edit" (ExerciseFormSheet .edit on a seeded exercise),
/// "detail" (ExerciseDetailSheet on a seeded exercise with entries), "entry" (EntryEditSheet on a seeded entry).
struct DebugPreviewRoot: View {
    var name: String

    var body: some View {
        // STUB — replaced in wave 3.
        Text("Preview '\(name)' not implemented yet")
            .foregroundStyle(Tokens.ink)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Tokens.paper.ignoresSafeArea())
    }
}
#endif
