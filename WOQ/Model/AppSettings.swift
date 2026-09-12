import SwiftUI

/// The three appearance choices of the menu's Appearance page.
///
/// `system` is the default and the behaviour the app had before there was a
/// setting at all: the paper theme follows the iPhone's own light/dark switch
/// (PLAN.md section 2 "Appearance"). The raw values are written to
/// `UserDefaults` under `AppSettings.appearanceKey`, so they must never be
/// renamed — an unknown value falls back to `.system`.
nonisolated enum Appearance: String, CaseIterable, Identifiable, Sendable {
    case system
    case light
    case dark

    var id: String { rawValue }

    /// Label for the segmented control.
    var displayName: String {
        switch self {
        case .system: String(localized: "System")
        case .light: String(localized: "Light")
        case .dark: String(localized: "Dark")
        }
    }

    /// What to hand `preferredColorScheme` / the window override: `nil` means
    /// "do not override, follow the device".
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

/// `UserDefaults` keys for the handful of app settings.
///
/// Deliberately plain `@AppStorage` and no observable settings object: the
/// values are read in unrelated places (the app root, the Appearance page and
/// `WaterBackground`), and `@AppStorage` keeps every preview, the component
/// gallery and the `--preview` debug roots working without environment
/// plumbing.
///
/// Defaults when nothing has been written yet:
/// - `appearance` -> `Appearance.system.rawValue` ("system")
/// - `waterRipple` -> `true` (the in-progress card animates)
/// - `textFont` -> `AppFont.sfPro.rawValue` ("sfPro", the original look)
///
/// All defaults live at the `@AppStorage` declarations; there is no
/// `register(defaults:)` call, so reading the raw dictionary shows nothing until
/// Marco changes something.
nonisolated enum AppSettings {
    /// Stores an `Appearance` raw value.
    static let appearanceKey = "appearance"
    /// Stores a `Bool`: does the in-progress card's water animate?
    static let waterRippleKey = "waterRipple"
    /// Stores an `AppFont` raw value: the typeface every text in the app is set
    /// in (AppFont.swift). `WOQApp` reads it and puts the case into the
    /// environment, so sheets and the screen behind them change together.
    static let textFontKey = "textFont"
}
