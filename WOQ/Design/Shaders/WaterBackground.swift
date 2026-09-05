import Foundation
import SwiftUI

/// Slow water fill for the in-progress card background (PLAN.md section 8).
///
/// Only ever one card has it, and it is applied to a background rectangle,
/// never to content with text fields: every shaded view costs an offscreen
/// raster pass per frame. Under Reduce Motion, with "Animated water" switched
/// off in the menu (Appearance page), or when `WOQ_STATIC_WATER` is set, which
/// keeps screenshots deterministic, it degrades to a plain `Tokens.water` fill.
///
/// `Shader.Argument.color` resolves a dynamic `Color` against the appearance the
/// view is drawn in (verified on iOS 26.5), so the light/dark `Tokens.water` pair
/// can be handed to the shader directly — no `\.colorScheme` plumbing needed.
struct WaterBackground: View {
    var cornerRadius: CGFloat = Tokens.radius

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Marco's own switch (menu > Appearance > Animated water). Read straight
    /// from `UserDefaults` so toggling it restyles a visible card at once,
    /// without any environment plumbing (AppSettings.swift).
    @AppStorage(AppSettings.waterRippleKey) private var waterRipple = true

    /// Wall-clock origin for the shader's `time`: elapsed seconds keep float precision.
    @State private var start = Date()
    /// Random per-card phase so two cards never ripple in lockstep.
    @State private var phase = Float.random(in: 0..<(2 * .pi))

    private var isStatic: Bool {
        reduceMotion
            || !waterRipple
            || ProcessInfo.processInfo.environment["WOQ_STATIC_WATER"] != nil
    }

    var body: some View {
        Group {
            if isStatic {
                Rectangle()
                    .fill(Tokens.water)
            } else {
                TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
                    let time = Float(context.date.timeIntervalSince(start))
                    Rectangle()
                        .fill(Tokens.water)
                        .colorEffect(
                            ShaderLibrary.default.waterFill(
                                .boundingRect,
                                .float(time),
                                .float(phase),
                                .color(Tokens.water),
                                .color(Tokens.waterTint)
                            )
                        )
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .accessibilityHidden(true)
    }
}

#Preview {
    ZStack {
        Tokens.paper.ignoresSafeArea()
        WaterBackground()
            .frame(height: 120)
            .padding()
    }
}
