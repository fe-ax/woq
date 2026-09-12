import SwiftUI
import UIKit

/// Design tokens for WOQ. Every colour is a light/dark pair — "paper" and "dark
/// paper" — resolved from the system appearance; never use semantic system
/// colours. See PLAN.md section 7 and the "Appearance" row of section 2.
///
/// Dark paper keeps the light theme's *relationships*: a warm near-black page,
/// slightly lighter cards, warm off-white ink, and pastels that stay pastel so a
/// figure highlight or a lane stripe still reads as red / yellow / blue. Text
/// drawn on a pastel fill uses `inkOnPastel`, which is fixed dark in both modes.
nonisolated enum Tokens {

    // MARK: - Colours

    /// Page background, #F7F3E8 light / #1B1A17 dark.
    static let paper = Color(light: 0xF7F3E8, dark: 0x1B1A17)
    /// Card fill, #FFFDF8 / #24221E.
    static let card = Color(light: 0xFFFDF8, dark: 0x24221E)
    /// Lines, text and the punched plus circle, #111111 / #F1ECE1.
    static let ink = Color(light: 0x111111, dark: 0xF1ECE1)
    /// Secondary text, #6B665C / #A39D91.
    static let muted = Color(light: 0x6B665C, dark: 0xA39D91)
    /// Primary muscle, #F4A6A6 / #D48A8A.
    static let red = Color(light: 0xF4A6A6, dark: 0xD48A8A)
    /// Secondary muscle and the main ("develop") lane, #F6E3A1 / #D3BC74.
    static let yellow = Color(light: 0xF6E3A1, dark: 0xD3BC74)
    /// Stabiliser muscle, #FBF2CF / #8C7F57. The dark value is a muted olive: on
    /// dark paper the stabiliser must stay the faintest of the three fills while
    /// still carrying `inkOnPastel` text on a chip.
    static let paleYellow = Color(light: 0xFBF2CF, dark: 0x8C7F57)
    /// In-progress lane, selection chips and the figure's selection fill,
    /// #A8C8F0 / #7FA4D6. The water has its own pair (`water`).
    static let blue = Color(light: 0xA8C8F0, dark: 0x7FA4D6)
    /// Lighter blue, #C6DCF7 / #9BBCE3.
    static let blueLight = Color(light: 0xC6DCF7, dark: 0x9BBCE3)
    /// Finalize flash, #B5DFB0 / #84B588.
    static let green = Color(light: 0xB5DFB0, dark: 0x84B588)
    /// Destructive actions and invalid input, #D9534F / #E27B76.
    static let danger = Color(light: 0xD9534F, dark: 0xE27B76)

    /// Text and glyphs drawn *on* a pastel fill (intensity chips, the L/R badge,
    /// the muscle filter chips): the pastels stay light-ish in both appearances,
    /// so their label stays dark in both. Fixed #111111.
    static let inkOnPastel = Color(hex: 0x111111)

    /// Fill of the hard offset shadow behind a card. Ink would read as a light
    /// halo on dark paper, so the dark value is a plain shade.
    static let shadow = Color(light: 0x111111, dark: 0x000000)

    /// Water base of the in-progress card, #A8C8F0 / #2C3D52.
    ///
    /// Unlike `blue` this one inverts: the card carries `ink`-coloured text and
    /// `muted` field labels directly on the water, and a light pastel behind
    /// them drops the label contrast to about 1.05:1 on dark paper. A deep blue
    /// keeps the same "one tinted card among paper cards" reading as the light
    /// theme (PLAN.md section 8).
    static let water = Color(light: 0xA3C5EF, dark: 0x2C3D52)
    /// Water wave band, #D5E4F8 / #4A6A90.
    ///
    /// Pulled further from `water` on 2026-09-05: the old pair (#C6DCF7 /
    /// #3E5878) moved a pixel by about 5/255 over a wave period, which Marco did
    /// not notice on the phone. These sit ~45/255 (light) and ~62/255 (dark)
    /// from the base, which together with the shader's full mix cap gives a
    /// visible but still soft ripple.
    static let waterTint = Color(light: 0xDFEBFA, dark: 0x51739C)

    // MARK: - Figure palette

    /// The dynamic palette handed to every `FigureView` / `FigurePairView` call
    /// site in the app.
    ///
    /// `FigureView` stays UIKit-free (a macOS script renders it), so the dynamic
    /// colours are built here and passed in. `Canvas` resolves them against its
    /// own environment, so the figure follows the appearance without any
    /// `colorScheme` plumbing at the call sites.
    static var figurePalette: FigurePalette {
        FigurePalette(
            card: card,
            ink: ink,
            primary: red,
            secondary: yellow,
            stabiliser: paleYellow,
            selected: blue
        )
    }

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

    // Fonts moved to WOQ/Design/AppFont.swift (Menu > Appearance > Font, 2026-09-12):
    // text uses `.appFont(_:weight:)`, `.appNumberFont(_:weight:)` and
    // `.appTitleFont()`, which read the chosen typeface from the environment.
    // `Tokens.titleFont` / `Tokens.numberFont(...)` were hard-wired to SF Pro and
    // would have ignored the setting, so they are gone.
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

    /// Creates a colour that resolves to `light` in the light appearance and to
    /// `dark` in the dark one, e.g. `Color(light: 0xF7F3E8, dark: 0x1B1A17)`.
    ///
    /// Backed by a dynamic `UIColor`, so SwiftUI re-resolves it wherever it is
    /// used — including inside a `Canvas` and a `.presentationBackground`.
    nonisolated init(light: UInt32, dark: UInt32) {
        self.init(
            uiColor: UIColor { traits in
                traits.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
            }
        )
    }
}

extension UIColor {
    /// Creates a fixed sRGB colour from a 24-bit hex value.
    nonisolated convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
