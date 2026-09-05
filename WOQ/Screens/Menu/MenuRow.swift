import SwiftUI

/// A root-menu row that pushes a submenu: title, one-line summary of the current
/// value, trailing chevron. The whole card is the button (`.plain`, so no system
/// tint or glass — PLAN.md pitfall 29).
struct MenuRow: View {
    var title: String
    var subtitle: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            OutlinedCard {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(.body, weight: .semibold))
                            .foregroundStyle(Tokens.ink)

                        // The backup summary carries a clock time, so monospaced
                        // digits like every other number in the app.
                        Text(subtitle)
                            .font(Tokens.numberFont(.caption))
                            .foregroundStyle(Tokens.muted)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Tokens.muted)
                }
                .contentShape(Rectangle())
            }
        }
        .buttonStyle(.plain)
    }
}

/// A row that performs an action right there: title, subtitle, an optional error
/// line and a trailing paper button. This is the row the menu had before it grew
/// pages, and the backup and developer pages still use it unchanged.
struct MenuActionRow: View {
    var title: String
    var subtitle: String
    var detail: String?
    var buttonTitle: String
    var isDisabled: Bool = false
    var action: () -> Void

    var body: some View {
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
}

/// Heading above a block on a menu page.
struct MenuSectionTitle: View {
    var text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.system(.body, weight: .semibold))
            .foregroundStyle(Tokens.ink)
    }
}

/// Muted caption under a control, explaining what it does.
struct MenuCaption: View {
    var text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(Tokens.muted)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    ZStack {
        Tokens.paper.ignoresSafeArea()
        VStack(spacing: Tokens.rowSpacing) {
            MenuRow(
                title: String(localized: "Appearance"),
                subtitle: String(localized: "System · Ripple on")
            ) {}

            MenuActionRow(
                title: String(localized: "Last backup"),
                subtitle: String(localized: "Never"),
                buttonTitle: String(localized: "Back up now")
            ) {}
        }
        .padding(16)
    }
}
