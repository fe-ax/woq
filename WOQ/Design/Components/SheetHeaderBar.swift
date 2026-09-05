import SwiftUI

/// Header row of every sheet: optional leading control (a back chevron for pushed
/// submenus), title, action buttons right. Replaces the navigation bar, which
/// stays hidden so iOS 26 cannot put glass on it (PLAN.md pitfall 7 and 29).
struct SheetHeaderBar<Leading: View, Trailing: View>: View {
    var title: String
    @ViewBuilder var leading: Leading
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            leading

            Text(title)
                .font(Tokens.titleFont)
                .foregroundStyle(Tokens.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.6)

            Spacer(minLength: 8)

            // The buttons keep their intrinsic width at every Dynamic Type
            // size — without this "Cancel" hyphenates onto two lines at XXXL.
            // The title shrinks instead.
            HStack(spacing: 8) { trailing }
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 12)
    }
}

extension SheetHeaderBar where Leading == EmptyView {
    /// The common form: title left, buttons right, nothing before the title.
    init(title: String, @ViewBuilder trailing: () -> Trailing) {
        self.title = title
        self.leading = EmptyView()
        self.trailing = trailing()
    }
}

/// Outlined round chevron for going back inside a sheet with pushed submenus.
struct SheetBackButton: View {
    var action: () -> Void

    var body: some View {
        RoundIconButton(
            systemName: "chevron.left",
            accessibilityLabel: String(localized: "Back"),
            action: action
        )
    }
}

#Preview {
    ZStack {
        Tokens.paper.ignoresSafeArea()
        VStack(spacing: 24) {
            SheetHeaderBar(title: String(localized: "New exercise")) {
                Button(String(localized: "Cancel")) {}
                    .buttonStyle(.paper)
                Button(String(localized: "Save")) {}
                    .buttonStyle(.ink)
            }
            SheetHeaderBar(
                title: String(localized: "Appearance"),
                leading: { SheetBackButton {} },
                trailing: {
                    Button(String(localized: "Close")) {}
                        .buttonStyle(.ink)
                }
            )
        }
    }
}
