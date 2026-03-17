#include <metal_stdlib>
using namespace metal;

struct GradientGlassLinesVertexOut {
    float4 position [[position]];
};

struct GradientGlassLinesUniforms {
    float3 iResolution;
    float2 iMouse;
    float  iTime;

    float  uAngle;
    float  uNoise;
    float  uBlindCount;
    float  uSpotlightRadius;
    float  uSpotlightSoftness;
    float  uSpotlightOpacity;
    float  uMirror;
    float  uDistort;
    float  uShineFlip;

    float3 uColor0;
    float3 uColor1;
    float3 uColor2;
    float3 uColor3;
    float3 uColor4;
    float3 uColor5;
    float3 uColor6;
    float3 uColor7;
    int    uColorCount;
};

vertex GradientGlassLinesVertexOut gradientGlassLinesVertex(uint vid [[vertex_id]],
                                                           constant float2 &viewportSize [[buffer(0)]]) {
    GradientGlassLinesVertexOut out;
    float2 positions[3] = {
        float2(-1.0, -1.0),
        float2( 3.0, -1.0),
        float2(-1.0,  3.0)
    };
    out.position = float4(positions[vid], 0.0, 1.0);
    return out;
}

float rand(float2 co) {
    return fract(sin(dot(co, float2(12.9898, 78.233))) * 43758.5453);
}

float2 rotate2D(float2 p, float a) {
    float c = cos(a);
    float s = sin(a);
    return float2(c * p.x - s * p.y, s * p.x + c * p.y);
}

float3 getGradientColor(float t,
                        constant GradientGlassLinesUniforms &u) {
    float tt = clamp(t, 0.0, 1.0);
    int count = u.uColorCount;
    if (count < 2) count = 2;
    float scaled = tt * float(count - 1);
    float seg = floor(scaled);
    float f = fract(scaled);

    if (seg < 1.0) return mix(u.uColor0, u.uColor1, f);
    if (seg < 2.0 && count > 2) return mix(u.uColor1, u.uColor2, f);
    if (seg < 3.0 && count > 3) return mix(u.uColor2, u.uColor3, f);
    if (seg < 4.0 && count > 4) return mix(u.uColor3, u.uColor4, f);
    if (seg < 5.0 && count > 5) return mix(u.uColor4, u.uColor5, f);
    if (seg < 6.0 && count > 6) return mix(u.uColor5, u.uColor6, f);
    if (seg < 7.0 && count > 7) return mix(u.uColor6, u.uColor7, f);
    if (count > 7) return u.uColor7;
    if (count > 6) return u.uColor6;
    if (count > 5) return u.uColor5;
    if (count > 4) return u.uColor4;
    if (count > 3) return u.uColor3;
    if (count > 2) return u.uColor2;
    return u.uColor1;
}

fragment float4 gradientGlassLinesFragment(GradientGlassLinesVertexOut in [[stage_in]],
                                           constant GradientGlassLinesUniforms &u [[buffer(0)]]) {
    float2 fragCoord = in.position.xy;
    float2 uv0 = fragCoord / u.iResolution.xy;

    float aspect = u.iResolution.x / u.iResolution.y;
    float2 p = uv0 * 2.0 - 1.0;
    p.x *= aspect;
    float2 pr = rotate2D(p, u.uAngle);
    pr.x /= aspect;
    float2 uv = pr * 0.5 + 0.5;

    float2 uvMod = uv;
    if (u.uDistort > 0.0) {
        float a = uvMod.y * 6.0;
        float b = uvMod.x * 6.0;
        float w = 0.01 * u.uDistort;
        uvMod.x += sin(a) * w;
        uvMod.y += cos(b) * w;
    }

    float t = uvMod.x;
    if (u.uMirror > 0.5) {
        t = 1.0 - abs(1.0 - 2.0 * fract(t));
    }
    float3 base = getGradientColor(t, u);

    float2 offset = float2(u.iMouse.x / u.iResolution.x,
                           u.iMouse.y / u.iResolution.y);
    float d = length(uv0 - offset);
    float r = max(u.uSpotlightRadius, 1e-4);
    float dn = d / r;
    float spot = (1.0 - 2.0 * pow(dn, u.uSpotlightSoftness)) * u.uSpotlightOpacity;
    float3 cir = float3(spot);

    float stripe = fract(uvMod.x * max(u.uBlindCount, 1.0));
    if (u.uShineFlip > 0.5) {
        stripe = 1.0 - stripe;
    }
    float3 ran = float3(stripe);

    float3 col = cir + base - ran;
    col += (rand(fragCoord + u.iTime) - 0.5) * u.uNoise;

    return float4(col, 1.0);
}

