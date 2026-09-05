import SwiftUI

/// Black circle with the plus punched out, so the paper background shows through.
/// See PLAN.md section 7 and pitfall 16: the destination-out blend must sit inside a compositing group.
struct PunchedPlusButton: View {
    var diameter: CGFloat = 44
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Tokens.ink)
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .blendMode(.destinationOut)
            }
            .frame(width: diameter, height: diameter)
            .compositingGroup()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(localized: "Add exercise"))
    }
}

#Preview {
    ZStack {
        Tokens.paper
        PunchedPlusButton {}
    }
}
