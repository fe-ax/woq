import SwiftUI

/// Menu page: the theme override and the water animation.
///
/// Both values live in `UserDefaults` (`AppSettings`) and are read straight from
/// `@AppStorage` here, by `WOQApp` (which applies the theme) and by
/// `WaterBackground` (which stops rippling). Changing one therefore updates the
/// open sheet, the screen behind it and any visible in-progress card at once,
/// without an observable settings object.
struct AppearancePage: View {
    @AppStorage(AppSettings.appearanceKey) private var appearanceRaw = Appearance.system.rawValue
    @AppStorage(AppSettings.waterRippleKey) private var waterRipple = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Tokens.rowSpacing) {
                appearanceBlock
                rippleBlock
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
                    .font(.system(.body, weight: .semibold))
                    .foregroundStyle(Tokens.ink)
                    .tint(Tokens.ink)

                MenuCaption(
                    String(localized: "The in-progress card ripples slowly. Off shows still water; Reduce Motion always stills it.")
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Storage

    /// `@AppStorage` holds the raw string (an unknown value must not crash), the
    /// control wants the enum.
    private var appearance: Binding<Appearance> {
        Binding(
            get: { Appearance(rawValue: appearanceRaw) ?? .system },
            set: { appearanceRaw = $0.rawValue }
        )
    }

    /// One-line summary for the row on the root page, e.g. "System · Ripple on".
    static func summary(appearanceRaw: String, waterRipple: Bool) -> String {
        let appearance = Appearance(rawValue: appearanceRaw) ?? .system
        let ripple = waterRipple
            ? String(localized: "Ripple on")
            : String(localized: "Ripple off")
        return "\(appearance.displayName) · \(ripple)"
    }
}

#Preview {
    ZStack {
        Tokens.paper.ignoresSafeArea()
        AppearancePage()
    }
}
