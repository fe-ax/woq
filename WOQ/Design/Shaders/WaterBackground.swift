import Foundation
import SwiftUI

/// Slow water fill for the in-progress card background (PLAN.md section 8).
///
/// Only ever one card has it, and it is applied to a background rectangle,
/// never to content with text fields: every shaded view costs an offscreen
/// raster pass per frame. Under Reduce Motion — or when `WOQ_STATIC_WATER` is
/// set, which keeps screenshots deterministic — it degrades to a plain
/// `Tokens.blue` fill.
struct WaterBackground: View {
    var cornerRadius: CGFloat = Tokens.radius

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Wall-clock origin for the shader's `time`: elapsed seconds keep float precision.
    @State private var start = Date()
    /// Random per-card phase so two cards never ripple in lockstep.
    @State private var phase = Float.random(in: 0..<(2 * .pi))

    private var isStatic: Bool {
        reduceMotion || ProcessInfo.processInfo.environment["WOQ_STATIC_WATER"] != nil
    }

    var body: some View {
        Group {
            if isStatic {
                Rectangle()
                    .fill(Tokens.blue)
            } else {
                TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
                    let time = Float(context.date.timeIntervalSince(start))
                    Rectangle()
                        .fill(Tokens.blue)
                        .colorEffect(
                            ShaderLibrary.default.waterFill(
                                .boundingRect,
                                .float(time),
                                .float(phase),
                                .color(Tokens.blue),
                                .color(Tokens.blueLight)
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
