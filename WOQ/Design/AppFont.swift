import SwiftUI
import UIKit

/// The text font chosen in Menu > Appearance (PLAN.md section 2, "Font", 2026-09-12).
///
/// Four fonts that ship with iOS, so nothing is bundled: SF Pro (the look the
/// app had from the start), SF Mono (Xcode's and Terminal's default), Menlo (the
/// classic Terminal font) and Courier New (the typewriter). The raw values are
/// written to `UserDefaults` under `AppSettings.textFontKey` and must never be
/// renamed; an unknown value falls back to `.sfPro`.
///
/// How it reaches the text: `WOQApp` puts the chosen case into the environment
/// (`\.appFont`), and views never call `.font(.headline)` themselves but
/// `.appFont(.headline)`, `.appNumberFont(.headline)` or `.appTitleFont()`, which
/// read the environment and build the `Font` (PLAN.md pitfall: a plain `.font`
/// silently ignores the setting). Dynamic Type keeps working: the two system
/// designs scale by text style on their own, and the two named fonts go through
/// `Font.custom(_:size:relativeTo:)` with the style's default size at the Large
/// content size as their base.
///
/// SF Symbols keep their own `.font(.system(size:weight:))`: that is a glyph
/// size, not text, and the symbol fonts are not affected by the setting.
enum AppFont: String, CaseIterable, Identifiable, Sendable {
    case sfPro
    case sfMono
    case menlo
    case courierNew

    var id: String { rawValue }

    /// Proper names, shown verbatim (not localized).
    var displayName: String {
        switch self {
        case .sfPro: "SF Pro"
        case .sfMono: "SF Mono"
        case .menlo: "Menlo"
        case .courierNew: "Courier New"
        }
    }

    /// One-line description for the Appearance page.
    var caption: String {
        switch self {
        case .sfPro: String(localized: "The iPhone's own typeface")
        case .sfMono: String(localized: "Xcode and Terminal")
        case .menlo: String(localized: "The classic Terminal font")
        case .courierNew: String(localized: "Typewriter")
        }
    }

    /// True for every font but SF Pro; digits line up by themselves then.
    var isMonospaced: Bool { self != .sfPro }

    /// Family name for `Font.custom`; nil for the two system designs.
    private var familyName: String? {
        switch self {
        case .sfPro, .sfMono: nil
        case .menlo: "Menlo"
        case .courierNew: "Courier New"
        }
    }

    private var design: Font.Design {
        self == .sfMono ? .monospaced : .default
    }

    // MARK: - Fonts

    /// A text style in this font. Replaces `Font.system(style, weight:)`.
    func font(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        guard let familyName else {
            return .system(style, design: design, weight: weight)
        }
        return Font.custom(familyName, size: Self.baseSize(of: style), relativeTo: style)
            .weight(Self.availableWeight(weight))
    }

    /// A text style with monospaced digits, for anything containing numbers
    /// (`Tokens.numberFont(_:weight:)` used to be this).
    func numberFont(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        font(style, weight: weight).monospacedDigit()
    }

    /// A fixed point size in this font, for the few labels that do not follow
    /// Dynamic Type (the header title, the keyboard bar).
    func font(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        guard let familyName else {
            return .system(size: size, weight: weight, design: design)
        }
        return Font.custom(familyName, fixedSize: size).weight(Self.availableWeight(weight))
    }

    /// The header title, bold 28 pt (`Tokens.titleFont` used to be this).
    var titleFont: Font { font(size: 28, weight: .bold) }

    // MARK: - Helpers

    /// Menlo and Courier New ship a regular and a bold face only; asking for
    /// semibold would silently render regular, so anything from medium up is
    /// bold and the rest regular.
    private static func availableWeight(_ weight: Font.Weight) -> Font.Weight {
        switch weight {
        case .medium, .semibold, .bold, .heavy, .black: .bold
        default: .regular
        }
    }

    /// The style's point size at the Large content size — the base that
    /// `Font.custom(_:size:relativeTo:)` scales from.
    private static func baseSize(of style: Font.TextStyle) -> CGFloat {
        let traits = UITraitCollection(preferredContentSizeCategory: .large)
        return UIFont.preferredFont(forTextStyle: style.uiTextStyle, compatibleWith: traits).pointSize
    }
}

private extension Font.TextStyle {
    var uiTextStyle: UIFont.TextStyle {
        switch self {
        case .largeTitle: .largeTitle
        case .title: .title1
        case .title2: .title2
        case .title3: .title3
        case .headline: .headline
        case .subheadline: .subheadline
        case .body: .body
        case .callout: .callout
        case .footnote: .footnote
        case .caption: .caption1
        case .caption2: .caption2
        case .extraLargeTitle: .extraLargeTitle
        case .extraLargeTitle2: .extraLargeTitle2
        @unknown default: .body
        }
    }
}

// MARK: - Environment

extension EnvironmentValues {
    /// The font every text in the app is set in; `WOQApp` writes it from
    /// `UserDefaults` so sheets and the screen behind them change together.
    @Entry var appFont: AppFont = .sfPro
}

// MARK: - View modifiers

private struct AppFontModifier: ViewModifier {
    @Environment(\.appFont) private var appFont
    var style: Font.TextStyle
    var weight: Font.Weight
    var monospacedDigits: Bool

    func body(content: Content) -> some View {
        content.font(
            monospacedDigits
                ? appFont.numberFont(style, weight: weight)
                : appFont.font(style, weight: weight)
        )
    }
}

private struct AppFixedFontModifier: ViewModifier {
    @Environment(\.appFont) private var appFont
    var size: CGFloat
    var weight: Font.Weight

    func body(content: Content) -> some View {
        content.font(appFont.font(size: size, weight: weight))
    }
}

private struct AppTitleFontModifier: ViewModifier {
    @Environment(\.appFont) private var appFont

    func body(content: Content) -> some View {
        content.font(appFont.titleFont)
    }
}

extension View {
    /// Text in the app font at a Dynamic Type style. Use instead of `.font(.headline)`.
    func appFont(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> some View {
        modifier(AppFontModifier(style: style, weight: weight, monospacedDigits: false))
    }

    /// Text containing numbers: the app font with monospaced digits. Use instead
    /// of `.font(Tokens.numberFont(...))`.
    func appNumberFont(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> some View {
        modifier(AppFontModifier(style: style, weight: weight, monospacedDigits: true))
    }

    /// Text at a fixed point size in the app font. Use instead of
    /// `.font(.system(size:weight:))` on text (not on SF Symbols).
    func appFont(size: CGFloat, weight: Font.Weight = .regular) -> some View {
        modifier(AppFixedFontModifier(size: size, weight: weight))
    }

    /// The 28 pt bold header title. Use instead of `.font(Tokens.titleFont)`.
    func appTitleFont() -> some View {
        modifier(AppTitleFontModifier())
    }
}
