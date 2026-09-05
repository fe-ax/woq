#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// Background of the single in-progress card (PLAN.md section 8).
//
// colorEffect signature: (float2 position, half4 currentColor, <custom args>...) -> half4 (premultiplied).
// The custom arguments must match the Swift call order exactly, otherwise the
// effect fails silently and the view draws unfiltered (PLAN.md pitfall 6):
//   ShaderLibrary.default.waterFill(.boundingRect, .float(t), .float(phase), .color(base), .color(tint))
//
// `time` is seconds since the view appeared, never a reference-date interval:
// float loses sub-second precision around 8e8.
[[ stitchable ]] half4 waterFill(float2 position, half4 color,
                                 float4 bounds, float time, float phase,
                                 half4 base, half4 tint) {
    float2 uv = (position - bounds.xy) / max(bounds.zw, float2(1.0));
    float t = time * 0.35 + phase;
    float w = sin(uv.x * 4.0 + t)
            + sin((uv.x * 2.0 + uv.y * 3.0) * 1.7 - t * 1.3)
            + sin((uv.y * 5.0 - uv.x * 1.5) + t * 0.7 + phase * 2.0);
    // 0...1 caustic-like blend, capped so the bands stay a barely-there ripple.
    half k = clamp(half(0.5 + 0.5 * (w / 3.0)), half(0.0), half(1.0)) * half(0.6);
    half4 c = mix(base, tint, k);
    return half4(c.rgb * color.a, color.a);        // keep premultiplied alpha of the underlying fill
}
