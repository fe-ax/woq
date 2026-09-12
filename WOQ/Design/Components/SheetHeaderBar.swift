import SwiftUI

/// Header row of every sheet: optional leading control (a back chevron for pushed
/// submenus), title, action buttons right. Replaces the navigation bar, which
/// stays hidden so iOS 26 cannot put glass on it (PLAN.md pitfall 7 and 29).
struct SheetHeaderBar<Leading: View, Trailing: View>: View {
    var title: String
    /// Makes the title itself a `.plain` button (the add sheet switches between the
    /// form and the preset list by tapping it). nil = plain text.
    var onTitleTap: (() -> Void)? = nil
    @ViewBuilder var leading: Leading
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            leading

            if let onTitleTap {
                Button(action: onTitleTap) { titleText }
                    .buttonStyle(.plain)
            } else {
                titleText
            }

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

    /// With a leading control the bar is tight ("New exercise" next to the switch
    /// button plus Cancel/Save), so the title shrinks on one line instead of
    /// wrapping and pushing the content down; without one it may wrap once.
    private var titleText: some View {
        Text(title)
            .appTitleFont()
            .foregroundStyle(Tokens.ink)
            .lineLimit(Leading.self == EmptyView.self ? 2 : 1)
            .minimumScaleFactor(0.6)
            .contentTransition(.opacity)
    }
}

extension SheetHeaderBar where Leading == EmptyView {
    /// The common form: title left, buttons right, nothing before the title.
    init(title: String, onTitleTap: (() -> Void)? = nil, @ViewBuilder trailing: () -> Trailing) {
        self.title = title
        self.onTitleTap = onTitleTap
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
