#version 330 core
// ant_cache_spectrum8_liquid_light
// Holographic interference fused with Liquid Light Rainbow fluid FBM warp + chromatic aberration
// Audio history (spectrum0..7) + Frame cache history (samp,samp1..samp8) - EXTREME

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform sampler2D samp1;
uniform sampler2D samp2;
uniform sampler2D samp3;
uniform sampler2D samp4;
uniform sampler2D samp5;
uniform sampler2D samp6;
uniform sampler2D samp7;
uniform sampler2D samp8;

uniform sampler1D spectrum0;
uniform sampler1D spectrum1;
uniform sampler1D spectrum2;
uniform sampler1D spectrum3;
uniform sampler1D spectrum4;
uniform sampler1D spectrum5;
uniform sampler1D spectrum6;
uniform sampler1D spectrum7;

uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;

const float TAU = 6.28318530718;
const float PI  = 3.14159265359;

float specHist(int i, float f) {
    if (i == 0) return texture(spectrum0, f).r;
    if (i == 1) return texture(spectrum1, f).r;
    if (i == 2) return texture(spectrum2, f).r;
    if (i == 3) return texture(spectrum3, f).r;
    if (i == 4) return texture(spectrum4, f).r;
    if (i == 5) return texture(spectrum5, f).r;
    if (i == 6) return texture(spectrum6, f).r;
    return texture(spectrum7, f).r;
}

vec4 cacheHist(int i, vec2 uv) {
    if (i == 0) return texture(samp,  uv);
    if (i == 1) return texture(samp1, uv);
    if (i == 2) return texture(samp2, uv);
    if (i == 3) return texture(samp3, uv);
    if (i == 4) return texture(samp4, uv);
    if (i == 5) return texture(samp5, uv);
    if (i == 6) return texture(samp6, uv);
    if (i == 7) return texture(samp7, uv);
    return texture(samp8, uv);
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
