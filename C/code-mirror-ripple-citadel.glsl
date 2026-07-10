#version 330 core
// code-mirror-ripple-citadel: enhanced remix of the mirror shader family.
in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform vec2 iResolution;
uniform float time_f;
uniform vec4 iMouse;
uniform float amp;
uniform float amp_peak;
uniform float amp_rms;
uniform float amp_smooth;
uniform float amp_low;
uniform float amp_mid;
uniform float amp_high;
uniform float iamp;

const float PI = 3.14159265359;
const float TAU = 6.28318530718;
const int STYLE = 18;
const float SEGMENTS = 7.0;
const float FIELD_SCALE = 1.09;
const float SPIN = 0.12;
const float WARP = 0.57;
const float EFFECT_MIX = 0.63;
const float HUE_SEED = 0.49;

mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

float hash21(vec2 p) {
    vec3 q = fract(vec3(p.xyx) * vec3(0.1031, 0.11369, 0.13787));
    q += dot(q, q.yzx + 19.19);
    return fract((q.x + q.y) * q.z);
}

vec2 mirrorTile(vec2 uv) {
    vec2 m = mod(uv, 2.0);
    return 1.0 - abs(m - 1.0);
}

vec2 kaleido(vec2 p, float segments) {
    float r = length(p);
    float a = atan(p.y, p.x);
    float wedge = TAU / max(segments, 2.0);
    a = abs(mod(a + 0.5 * wedge, wedge) - 0.5 * wedge);
    return r * vec2(cos(a), sin(a));
}

vec3 palette(float x) {
    vec3 phase = vec3(HUE_SEED, HUE_SEED + 0.31, HUE_SEED + 0.67);
    return 0.52 + 0.48 * cos(TAU * (x + phase));
}

vec2 mirrorField(vec2 p, float t, float lo, float mi, float hi) {
    float r = max(length(p), 0.001);
    float a = atan(p.y, p.x);

    if (STYLE == 0) {
        p = kaleido(p * rot(t * SPIN), SEGMENTS + floor(mi * 4.0));
        p = abs(p) - vec2(0.18 + lo * 0.08);
    } else if (STYLE == 1) {
        p = kaleido(p, SEGMENTS);
        p += normalize(p + vec2(0.001)) * sin(r * 22.0 - t * 2.4) * (0.07 + hi * 0.05);
    } else if (STYLE == 2) {
        p += vec2(sin(p.y * 11.0 + t), cos(p.x * 9.0 - t)) * (0.08 + lo * 0.05);
        p = abs(p * rot(t * SPIN)) - 0.24;
    } else if (STYLE == 3) {
        p = kaleido(p, SEGMENTS);
        p *= 0.72 + 0.28 * cos(a * 5.0 - t * 1.3);
    } else if (STYLE == 4) {
        p = abs(p);
        if (p.y > p.x) p = p.yx;
        p = abs(p * rot(0.3 + t * SPIN)) - vec2(0.22, 0.12);
    } else if (STYLE == 5) {
        p = vec2(a / TAU + t * 0.04, log(r) * 0.22 - t * 0.08);
        p = abs(fract(p * vec2(3.0, 2.0) + 0.5) - 0.5);
    } else if (STYLE == 6) {
        p = kaleido(p, SEGMENTS + floor(hi * 6.0));
        for (int i = 0; i < 4; ++i) p = abs(p * rot(0.38 + float(i) * 0.17 + t * 0.03)) - 0.19;
    } else if (STYLE == 7) {
        p *= rot(WARP / r + t * SPIN);
        p = kaleido(p, SEGMENTS);
    } else if (STYLE == 8) {
        p = vec2(max(abs(p.x), abs(p.y)), min(abs(p.x), abs(p.y)));
        p.x += sin(p.y * 18.0 - t * 2.0) * 0.07;
    } else if (STYLE == 9) {
        p = kaleido(p, SEGMENTS);
        p = abs(fract(p * (2.4 + mi) + 0.5) - 0.5);
    } else if (STYLE == 10) {
        p += normalize(p + vec2(0.001)) * sin(r * (18.0 + lo * 12.0) - t * 2.2) * 0.10;
        p = abs(p * rot(sin(t * 0.2) * 0.5));
    } else if (STYLE == 11) {
        p += vec2(sin(p.y * 16.0 + t * 1.7), sin(p.x * 14.0 - t * 1.3)) * 0.07;
        p = kaleido(p, SEGMENTS);
    } else if (STYLE == 12) {
        p = kaleido(p, SEGMENTS);
        p *= 0.78 + 0.22 * sin(a * 7.0 + r * 8.0 - t);
    } else if (STYLE == 13) {
        p = abs(fract(p * rot(t * SPIN) * (3.0 + mi) + 0.5) - 0.5);
        p = kaleido(p, SEGMENTS);
    } else if (STYLE == 14) {
        vec2 q = p * rot(t * SPIN);
        p = (abs(q) + abs(q * rot(0.78))) * 0.62 - 0.22;
    } else if (STYLE == 15) {
        p = kaleido(p, SEGMENTS);
        p.x += floor((p.y + 0.5) * 16.0) * 0.012 * sin(t * 3.0);
        p = abs(p) - vec2(0.14, 0.24);
    } else if (STYLE == 16) {
        float lens = 1.0 / (1.0 + (2.0 + lo * 2.0) * r * r);
        p *= 1.25 - lens * 0.72;
        p = kaleido(p * rot(t * 0.08), SEGMENTS);
    } else if (STYLE == 17) {
        p = kaleido(p, SEGMENTS + floor(mi * 8.0));
        p = abs(p * FIELD_SCALE) - vec2(0.16 + hi * 0.05);
    } else if (STYLE == 18) {
        p += normalize(p + vec2(0.001)) * sin(r * 28.0 - t * (2.0 + lo * 3.0)) * 0.08;
        p = abs(fract(p * 1.8 + 0.5) - 0.5);
    } else if (STYLE == 19) {
        float cell = floor(a / (TAU / SEGMENTS));
        p *= rot((hash21(vec2(cell, 2.0)) - 0.5) * (0.8 + hi));
        p = abs(p) - vec2(0.20, 0.11);
    } else if (STYLE == 20) {
        p = kaleido(p * (1.0 + lo * 0.25), SEGMENTS + floor(lo * 6.0));
        p *= rot(t * SPIN + sin(r * 12.0 - t) * 0.3);
    } else if (STYLE == 21) {
        float lr = fract(log(r) * (1.4 + lo) - t * 0.18);
        p = vec2(cos(a + lr * 3.0), sin(a + lr * 3.0)) * lr;
        p = kaleido(p, SEGMENTS);
    } else if (STYLE == 22) {
        p = kaleido(p, SEGMENTS + floor(hi * 10.0));
        p *= 0.66 + 0.34 * cos(a * 8.0 - t * 1.8);
        p = abs(p) - 0.13;
    } else if (STYLE == 23) {
        p = abs(p);
        p = abs(p * rot(PI * 0.25)) + abs(p * rot(-PI * 0.25));
        p = abs(fract(p * 2.1 + 0.5) - 0.5);
    } else {
        p *= rot(sin(r * 9.0 - t) * WARP);
        p = kaleido(p, SEGMENTS);
        p += vec2(sin(p.y * 10.0), cos(p.x * 12.0)) * 0.06;
    }
    return p;
}

vec3 chromaSample(vec2 uv, vec2 direction, float spread) {
    vec2 px = 1.0 / max(iResolution, vec2(1.0));
    vec2 d = direction * px * spread;
    vec2 u0 = mirrorTile(uv + d);
    vec2 u1 = mirrorTile(uv);
    vec2 u2 = mirrorTile(uv - d);
    return vec3(texture(samp, u0).r, texture(samp, u1).g, texture(samp, u2).b);
}

void main() {
    float lo = clamp(amp_low, 0.0, 1.0);
    float mi = clamp(amp_mid, 0.0, 1.0);
    float hi = clamp(amp_high, 0.0, 1.0);
    float peak = clamp(amp_peak, 0.0, 1.0);
    float rms = clamp(amp_rms, 0.0, 1.0);
    float smoothAmp = clamp(amp_smooth, 0.0, 1.0);
    float aspect = iResolution.x / max(iResolution.y, 1.0);
    vec2 ar = vec2(aspect, 1.0);
    vec2 center = (iMouse.z > 0.5 || iMouse.w > 0.5) ? iMouse.xy / max(iResolution, vec2(1.0)) : vec2(0.5);
    vec2 p = (tc - center) * ar;
    float originalRadius = length(p);
    float t = time_f;

    p *= rot(t * SPIN * (0.35 + smoothAmp * 0.4));
    p = mirrorField(p * FIELD_SCALE, t, lo, mi, hi);

    // Recursive reflective refinement shared by the family.
    for (int i = 0; i < 3; ++i) {
        float fi = float(i);
        p = abs(p * rot(0.13 + fi * 0.41 + t * 0.025)) - vec2(0.12 + fi * 0.025);
        p *= 1.06 + WARP * 0.06 + lo * 0.025;
    }

    vec2 baseUV = p / ar + center;
    vec2 direction = normalize(p + vec2(0.0001));
    float dispersion = 1.2 + hi * 8.0 + peak * 3.0;
    vec3 mirrored = chromaSample(baseUV, direction, dispersion);

    // Three reflected echo taps add depth without requiring feedback textures.
    vec3 echoes = vec3(0.0);
    for (int i = 1; i <= 3; ++i) {
        float fi = float(i);
        vec2 echoUV = baseUV + direction * (0.012 * fi + rms * 0.008) * sin(t * 0.6 + fi * 1.9);
        echoes += texture(samp, mirrorTile(echoUV)).rgb / (2.2 + fi);
    }

    float fieldRadius = length(p);
    float angle = atan(p.y, p.x);
    float bands = 0.5 + 0.5 * sin(fieldRadius * (24.0 + float(STYLE % 7) * 3.0) - t * (1.6 + lo * 2.4));
    float seam = exp(-18.0 * min(abs(p.x), abs(p.y)));
    vec3 tint = palette(angle / TAU + fieldRadius * 0.7 + t * 0.035);
    vec3 fx = mix(mirrored, mirrored + echoes * 0.55, 0.65);
    fx *= mix(vec3(1.0), tint, 0.28 + mi * 0.18);
    fx += tint * seam * (0.08 + hi * 0.16);
    fx += tint * pow(bands, 7.0) * (0.05 + peak * 0.18);

    vec3 source = texture(samp, tc).rgb;
    vec3 outCol = mix(source, fx, EFFECT_MIX);
    float vignette = 1.0 - smoothstep(0.52, 1.30, originalRadius);
    outCol *= 0.78 + vignette * (0.25 + smoothAmp * 0.10);
    outCol += max(outCol - 0.62, 0.0) * (0.22 + peak * 0.20);
    outCol *= 1.0 + peak * 0.30;
    outCol = mix(outCol, outCol * vec3(1.0 + lo * 0.24, 1.0 + mi * 0.12, 1.0 + hi * 0.28), 0.72);
    outCol = outCol / (1.0 + max(outCol - 1.0, 0.0));

    color = vec4(clamp(outCol, 0.0, 1.0), texture(samp, tc).a);
}

