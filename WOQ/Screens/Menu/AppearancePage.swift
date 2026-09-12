import SwiftUI

/// Menu page: the theme override, the water animation and the text font.
///
/// All three values live in `UserDefaults` (`AppSettings`) and are read straight
/// from `@AppStorage` here, by `WOQApp` (which applies the theme and puts the
/// font into the environment) and by `WaterBackground` (which stops rippling).
/// Changing one therefore updates the open sheet, the screen behind it and any
/// visible in-progress card at once, without an observable settings object.
struct AppearancePage: View {
    @AppStorage(AppSettings.appearanceKey) private var appearanceRaw = Appearance.system.rawValue
    @AppStorage(AppSettings.waterRippleKey) private var waterRipple = true
    @AppStorage(AppSettings.textFontKey) private var textFontRaw = AppFont.sfPro.rawValue

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.rowSpacing) {
                appearanceBlock
                rippleBlock
                fontBlock
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .scrollEdgeEffectStyle(.hard, for: .top)
    }

    // MARK: - Blocks

    private var appearanceBlock: some View {
        OutlinedCard {
            VStack(alignment: .leading, spacing: 8) {
                MenuSectionTitle(String(localized: "Appearance"))

                SegmentedRow(
                    options: Appearance.allCases,
                    label: \.displayName,
                    selection: appearance
                )

                MenuCaption(String(localized: "System follows the iPhone setting"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var rippleBlock: some View {
        OutlinedCard {
            VStack(alignment: .leading, spacing: 4) {
                // Same look as the L/R toggle in ExerciseFormSheet: ink tint, ink label.
                Toggle(String(localized: "Animated water"), isOn: $waterRipple)
                    .appFont(.body, weight: .semibold)
                    .foregroundStyle(Tokens.ink)
                    .tint(Tokens.ink)

                MenuCaption(
                    String(localized: "The in-progress card ripples slowly. Off shows still water; Reduce Motion always stills it.")
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// One row per font, each drawn in the font it selects — the row *is* the
    /// sample, so nothing has to be applied before Marco can see it.
    private var fontBlock: some View {
        OutlinedCard {
            VStack(alignment: .leading, spacing: 8) {
                MenuSectionTitle(String(localized: "Font"))

                VStack(spacing: 0) {
                    ForEach(Array(AppFont.allCases.enumerated()), id: \.element.id) { index, font in
                        if index > 0 {
                            Rectangle()
                                .fill(Tokens.ink)
                                .frame(height: Tokens.hairline)
                                .opacity(0.25)
                        }
                        fontRow(font)
                    }
                }

                MenuCaption(
                    String(localized: "Every text in the app; icons keep their size.")
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// Name and sample in *that* font (`font.font(...)` directly, not
    /// `.appFont(...)`, which would draw every row in the current setting), the
    /// description in the app font, and a lane node as the selection mark.
    private func fontRow(_ font: AppFont) -> some View {
        let isSelected = font.rawValue == textFontRaw

        return Button {
            guard !isSelected else { return }
            textFontRaw = font.rawValue
        } label: {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(font.displayName)
                        .font(font.font(.body, weight: .semibold))
                        .foregroundStyle(Tokens.ink)

                    Text(Self.sampleLine)
                        .font(font.numberFont(.subheadline))
                        .foregroundStyle(Tokens.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text(font.caption)
                        .appFont(.caption)
                        .foregroundStyle(Tokens.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Same 12 pt node as the queue's lane: blue when chosen.
                ZStack {
                    Circle()
                        .fill(isSelected ? Tokens.blue : Tokens.card)
                    Circle()
                        .strokeBorder(Tokens.ink, lineWidth: Tokens.line)
                }
                .frame(width: Tokens.node, height: Tokens.node)
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.snappy, value: isSelected)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(font.displayName), \(font.caption)")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    /// A row from the queue, so the sample shows letters, digits and the
    /// multiplication sign the app actually prints.
    private static let sampleLine = "Bench press · 40 \(String(localized: "kg")) \(Formatting.timesSign) 10"

    // MARK: - Storage

    /// `@AppStorage` holds the raw string (an unknown value must not crash), the
    /// control wants the enum.
    private var appearance: Binding<Appearance> {
        Binding(
            get: { Appearance(rawValue: appearanceRaw) ?? .system },
            set: { appearanceRaw = $0.rawValue }
        )
    }

    /// One-line summary for the row on the root page, e.g. "System · Ripple on · SF Mono".
    static func summary(appearanceRaw: String, waterRipple: Bool, textFontRaw: String) -> String {
        let appearance = Appearance(rawValue: appearanceRaw) ?? .system
        let ripple = waterRipple
            ? String(localized: "Ripple on")
            : String(localized: "Ripple off")
        let font = AppFont(rawValue: textFontRaw) ?? .sfPro
        return "\(appearance.displayName) · \(ripple) · \(font.displayName)"
    }
}

#Preview {
    ZStack {
        Tokens.paper.ignoresSafeArea()
        AppearancePage()
    }
}
