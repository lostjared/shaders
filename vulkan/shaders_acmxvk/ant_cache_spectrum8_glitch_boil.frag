#version 450

layout(set = 0, binding = 1, std140) uniform SpriteExtended {
    vec4 mouse;
    vec4 u0;
    vec4 u1;
    vec4 u2;
    vec4 u3;
    vec4 custom_uniforms[16];
    vec4 audio_bands;
    vec4 audio_history;
} ext;
#define amp_peak ext.u2.w
#define amp_smooth ext.u3.w
#define history_head int(ext.u3.x)
#define iResolution ext.u0.zw
#define iTime ext.u0.y
#define spectrum_history_head int(ext.audio_history.x)
#define spectrum_history_size int(ext.audio_history.y)

// ant_cache_spectrum8_glitch_boil
// Holographic fringe x glitch_boil2 multi-axis sine boil distortion
// Audio history (spectrum0..7) + Frame cache history (samp,samp1..samp8) - EXTREME
layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;
layout(set = 0, binding = 2) uniform sampler2DArray history;

#ifndef SIZE
#define SIZE 8
#endif
#ifndef CACHE_HISTORY_LAYER
#define CACHE_HISTORY_LAYER(index) ((history_head + (index)) % SIZE)
#endif
layout(set = 0, binding = 3) uniform sampler1D spectrum0;
layout(set = 0, binding = 4) uniform sampler1DArray spectrum_history;


#ifndef SPECTRUM_HISTORY_LAYER
#define SPECTRUM_HISTORY_LAYER(index) ((spectrum_history_head - ((index) % max(spectrum_history_size, 1)) + max(spectrum_history_size, 1)) % max(spectrum_history_size, 1))
#endif





const float TAU = 6.28318530718;

float specHist(int i, float f) {
    if (i == 0) return texture(spectrum0, f).r;
    if (i == 1) return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(1)))).r;
    if (i == 2) return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(2)))).r;
    if (i == 3) return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(3)))).r;
    if (i == 4) return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(4)))).r;
    if (i == 5) return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(5)))).r;
    if (i == 6) return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(6)))).r;
    return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(7)))).r;
}

vec4 cacheHist(int i, vec2 uv) {
    if (i == 0) return texture(samp,  uv);
    if (i == 1) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(0))));
    if (i == 2) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(1))));
    if (i == 3) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(2))));
    if (i == 4) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(3))));
    if (i == 5) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(4))));
    if (i == 6) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(5))));
    if (i == 7) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(6))));
    return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(7))));
}

vec3 palette(float t, vec3 d) {
    return 0.5 + 0.5 * cos(TAU * (vec3(1.0) * t + d));
}

float pingPong(float x, float L) {
    float m = mod(x, L * 2.0);
    return m <= L ? m : L * 2.0 - m;
}

void main() {
    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);
    float tt = pingPong(iTime, 10.0);

    vec3 acc = vec3(0.0);
    for (int i = 0; i < 8; i++) {
        float h  = specHist(i, 0.05 + float(i) * 0.06);
        float h2 = specHist(i, 0.55);
        float bass = specHist(i, 0.04);

        // glitch_boil multi-axis warp (audio scaled, not unbounded time)
        float warpScale = 0.04 + bass * 0.35;
        float boil = 0.0;
        boil += sin(tc.y * 20.0 + iTime * 6.0 + float(i)) * warpScale;
        boil += cos(tc.x * 30.0 + iTime * 4.0 + float(i) * 0.7) * warpScale;
        boil += sin((tc.x + tc.y) * 25.0 + iTime * 5.0) * warpScale * 0.5;
        vec2 buv = tc + vec2(boil, boil);
        // distorted re-map (analogous to texture(samp, sin(uv*time_t)))
        vec2 distUV = sin(buv * (0.6 + tt * 0.05) + float(i)) * 0.5 + 0.5;
        vec2 suv = mix(buv, distUV, 0.45);

        // Holographic fringe
        float ang = float(i) * 0.4 + h2 * 3.0;
        vec2 dir = vec2(cos(ang), sin(ang));
        float fringe = sin(dot(uv, dir) * (40.0 + h * 80.0) + iTime * (1.0 + h * 4.0));
        fringe = pow(fringe * 0.5 + 0.5, 4.0);
        suv += dir * fringe * 0.05 * (1.0 + h);

        vec3 c;
        c.r = cacheHist(i, fract(suv) + vec2(h * 0.1, 0.0)).r;
        c.g = cacheHist(i, fract(suv)).g;
        c.b = cacheHist(i, fract(suv) - vec2(h * 0.1, 0.0)).b;

        // boil mix toward base (anchors image)
        vec4 base = cacheHist(i, tc);
        c = mix(base.rgb, c, 0.6 + bass * 0.4);

        vec3 tint = palette(float(i) * 0.13 + h * 4.0, vec3(0.0, 0.33, 0.66));
        acc += (c + tint * fringe * 0.5) * (1.0 + h * 4.5 + bass * 3.0) * pow(0.83, float(i));
    }
    acc /= 3.0;
    acc *= 1.3 + amp_peak * 1.3;
    color = vec4(clamp(acc, 0.0, 1.0), 1.0);
}
