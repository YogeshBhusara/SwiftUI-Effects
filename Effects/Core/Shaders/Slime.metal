#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
};

struct SlimeUniforms {
    float3 iResolution;
    float  iTime;
    float3 iMouse;
    float3 iColor;
    float3 iCursorColor;
    float  iAnimationSize;
    int    iBallCount;
    float  iCursorBallSize;
    float  iClumpFactor;
    int    enableTransparency;
};

constant int MAX_BALLS = 50;

vertex VertexOut slimeVertex(uint vid [[vertex_id]],
                             constant float2 &viewportSize [[buffer(0)]]) {
    VertexOut out;
    float2 positions[3] = {
        float2(-1.0, -1.0),
        float2( 3.0, -1.0),
        float2(-1.0,  3.0)
    };
    out.position = float4(positions[vid], 0.0, 1.0);
    return out;
}

// Softer falloff for liquid-like merging: blobs connect with visible "necks" and separate cleanly
float getSlimeValue(float2 c, float r, float2 p) {
    float2 d = p - c;
    float dist2 = dot(d, d);
    float r2 = r * r;
    return r2 / max(dist2, 1e-5);
}

fragment float4 slimeFragment(VertexOut in [[stage_in]],
                              constant SlimeUniforms &u [[buffer(0)]],
                              const device float3 *iSlime [[buffer(1)]]) {
    float2 fc = in.position.xy;
    float scale = u.iAnimationSize / u.iResolution.y;
    float2 coord = (fc - u.iResolution.xy * 0.5) * scale;
    float2 mouseW = (u.iMouse.xy - u.iResolution.xy * 0.5) * scale;

    float m1 = 0.0;
    for (int i = 0; i < MAX_BALLS; i++) {
        if (i >= u.iBallCount) break;
        float3 mb = iSlime[i];
        m1 += getSlimeValue(mb.xy, mb.z, coord);
    }

    float m2 = getSlimeValue(mouseW, u.iCursorBallSize, coord);
    float total = m1 + m2;

    // Iso-surface threshold: higher = smaller blobs, visible "necks" when merging, clean divide when apart
    const float iso = 1.45;
    // Soft edge width from screen-space gradient for smooth liquid silhouette
    float fw = length(float2(dfdx(total), dfdy(total)));
    fw = max(0.15, fw * 1.5);
    float f = smoothstep(iso - fw, iso + fw, total);

    float3 cFinal = float3(0.0);
    if (total > 0.0) {
        float alpha1 = m1 / total;
        float alpha2 = m2 / total;
        cFinal = u.iColor * alpha1 + u.iCursorColor * alpha2;
    }

    float alpha = (u.enableTransparency != 0) ? f : 1.0;
    return float4(cFinal * f, alpha);
}

