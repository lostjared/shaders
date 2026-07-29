#version 330 core
// ant_cache_spectrum8_liquid_light
// Holographic interference fused with Liquid Light Rainbow fluid FBM warp + chromatic aberration
// Audio history (spectrum0..7) + Frame cache history (samp,samp1..samp8) - EXTREME

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform sampler2DArray history;
uniform int history_head;
#ifndef SIZE
#define SIZE 8
#endif
#ifndef CACHE_HISTORY_LAYER
#define CACHE_HISTORY_LAYER(index) ((history_head + (index)) % SIZE)
#endif

uniform sampler1D spectrum0;
uniform sampler1DArray spectrum_history;
uniform int spectrum_history_head;
uniform int spectrum_history_size;
#ifndef SPECTRUM_HISTORY_LAYER
#define SPECTRUM_HISTORY_LAYER(index) ((spectrum_history_head - ((index) % max(spectrum_history_size, 1)) + max(spectrum_history_size, 1)) % max(spectrum_history_size, 1))
#endif

uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;

const float TAU = 6.28318530718;
const float PI  = 3.14159265359;

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

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x),
               mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}

float fbm(vec2 p) {
    float v = 0.0, a = 0.5;
    mat2 r = mat2(0.87758, 0.47943, -0.47943, 0.87758);
    for (int k = 0; k < 5; k++) { v += a * vnoise(p); p = r * p * 2.02; a *= 0.5; }
    return v;
}

vec3 sampleLiquidSlot(int i, vec2 uv, float t, float h, float h2) {
    vec2 p = uv - 0.5;
    p.x *= iResolution.x / iResolution.y;
    vec2 q = vec2(fbm(p + vec2(0.0, 0.0) + 0.05 * t),
                  fbm(p + vec2(5.2, 1.3) + 0.05 * t));
    vec2 r = vec2(fbm(p + 4.0 * q + vec2(t * 0.2)),
                  fbm(p + 4.0 * q + vec2(t * 0.1, 2.8)));
    vec2 fluid = uv + r * (0.18 + h * 0.35);

    // Holographic fringe
    float ang = float(i) * 0.4 + h2 * 3.0;
    vec2 dir = vec2(cos(ang), sin(ang));
    float fringe = sin(dot(p, dir) * (40.0 + h * 80.0) + t * (1.0 + h * 4.0));
    fringe = pow(fringe * 0.5 + 0.5, 4.0);
    fluid += dir * fringe * 0.04 * (1.0 + h);

    vec3 c;
    c.r = cacheHist(i, fluid + vec2(h * 0.012, 0.0)).r;
    c.g = cacheHist(i, fluid).g;
    c.b = cacheHist(i, fluid - vec2(h * 0.012, 0.0)).b;

    vec3 neon = palette(length(q) + length(r) + float(i) * 0.13, vec3(0.0, 0.33, 0.66));
    return c * neon * 2.2 + neon * fringe * 0.4;
}

void main() {
    float t = iTime * 0.6;
    vec3 acc = vec3(0.0);
    for (int i = 0; i < 8; i++) {
        float h  = specHist(i, 0.05 + float(i) * 0.06);
        float h2 = specHist(i, 0.55);
        acc += sampleLiquidSlot(i, tc, t + float(i) * 0.7, h, h2) * pow(0.83, float(i));
    }
    acc /= 3.0;
    acc *= 1.25 + amp_smooth * 1.1;

    // Deep purple vignette from liquid_light
    vec2 vUV = tc * (1.0 - tc.yx);
    float vig = pow(vUV.x * vUV.y * 15.0, 0.2);
    acc = mix(vec3(0.05, 0.0, 0.1), acc * vig, vig);

    color = vec4(clamp(acc, 0.0, 1.0), 1.0);
}
