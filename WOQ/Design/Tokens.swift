import SwiftUI

/// Fixed design tokens for WOQ. Light mode only: never use semantic system colours.
/// See PLAN.md section 7.
nonisolated enum Tokens {

    // MARK: - Colours

    /// Page background, #F7F3E8.
    static let paper = Color(hex: 0xF7F3E8)
    /// Card fill, #FFFDF8.
    static let card = Color(hex: 0xFFFDF8)
    /// Lines, text and the punched plus circle, #111111.
    static let ink = Color(hex: 0x111111)
    /// Secondary text, #6B665C.
    static let muted = Color(hex: 0x6B665C)
    /// Primary muscle, #F4A6A6.
    static let red = Color(hex: 0xF4A6A6)
    /// Secondary muscle and the main ("develop") lane, #F6E3A1.
    static let yellow = Color(hex: 0xF6E3A1)
    /// Stabiliser muscle, #FBF2CF.
    static let paleYellow = Color(hex: 0xFBF2CF)
    /// In-progress lane and water base, #A8C8F0.
    static let blue = Color(hex: 0xA8C8F0)
    /// Water wave band, #C6DCF7.
    static let blueLight = Color(hex: 0xC6DCF7)
    /// Finalize flash, #B5DFB0.
    static let green = Color(hex: 0xB5DFB0)
    /// Destructive actions and invalid input, #D9534F.
    static let danger = Color(hex: 0xD9534F)

    // MARK: - Metrics

    /// Standard outline width.
    static let line: CGFloat = 1.5
    /// Thin rule width.
    static let hairline: CGFloat = 1
    /// Corner radius for every card and field.
    static let radius: CGFloat = 3
    /// Diameter of a lane node.
    static let node: CGFloat = 12
    /// Width of the vertical pastel lane stripe.
    static let laneStripe: CGFloat = 6
    /// Inner padding of a card.
    static let cardPadding: CGFloat = 12
    /// Vertical spacing between rows.
    static let rowSpacing: CGFloat = 10
    /// Width of the lane decoration column.
    static let laneColumn: CGFloat = 28
    /// Offset of the optional hard shadow behind a card.
    static let shadowOffset: CGFloat = 2

    // MARK: - Fonts

    /// Header title, SF Pro bold 28.
    static let titleFont = Font.system(size: 28, weight: .bold)

    /// A text style with monospaced digits, for anything containing numbers.
    static func numberFont(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        Font.system(style, design: .default, weight: weight).monospacedDigit()
    }

    /// A fixed-size font with monospaced digits.
    static func numberFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Font.system(size: size, weight: weight).monospacedDigit()
    }
}

extension Color {
    /// Creates a fixed sRGB colour from a 24-bit hex value, e.g. `Color(hex: 0xF7F3E8)`.
    nonisolated init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}
