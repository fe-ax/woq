#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// colorEffect signature: (float2 position, half4 currentColor, <custom args>...) -> half4 (premultiplied)
[[ stitchable ]] half4 waterFill(float2 position, half4 color,
                                 float4 bounds, float time, float phase,
                                 half4 base, half4 tint) {
    float2 uv = (position - bounds.xy) / max(bounds.zw, float2(1.0));
    float t = time * 0.35 + phase;
    float w = sin(uv.x * 4.0 + t)
            + sin((uv.x * 2.0 + uv.y * 3.0) * 1.7 - t * 1.3)
            + sin((uv.y * 5.0 - uv.x * 1.5) + t * 0.7 + phase * 2.0);
    half k = half(0.5 + 0.5 * (w / 3.0));          // 0...1
    half4 c = mix(base, tint, k);
    return half4(c.rgb * color.a, color.a);        // keep premultiplied alpha of the underlying fill
}

// layerEffect signature check: (float2 position, SwiftUI::Layer layer, <args>) -> half4
[[ stitchable ]] half4 passthrough(float2 position, SwiftUI::Layer layer) {
    return layer.sample(position);
}

// distortionEffect signature check: (float2 position, <args>) -> float2
[[ stitchable ]] float2 wobble(float2 position, float time) {
    return position + float2(0.0, sin(position.x * 0.05 + time) * 2.0);
}
