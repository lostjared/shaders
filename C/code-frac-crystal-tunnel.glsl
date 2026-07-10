#version 330 core
// code-frac-crystal-tunnel: generated remix of the frac shader family.
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform vec2 iResolution;
uniform float time_f;
uniform vec4 iMouse;
uniform float amp_peak;
uniform float amp_rms;
uniform float amp_smooth;
uniform float amp_low;
uniform float amp_mid;
uniform float amp_high;
uniform float iamp;

const float PI = 3.14159265359;
const float TAU = 6.28318530718;
const int STYLE = 7;
const float SEGMENTS = 5.0;
const float FOLD_SCALE = 1.78;
const float SPIN = 0.14;
const float WARP = 0.58;
const float TEX_MIX = 0.55;
const float HUE_RATE = 0.90;

mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

vec3 hsv2rgb(vec3 c) {
    vec3 p = abs(fract(c.xxx + vec3(0.0, 0.666667, 0.333333)) * 6.0 - 3.0);
    return c.z * mix(vec3(1.0), clamp(p - 1.0, 0.0, 1.0), c.y);
}

vec2 kaleido(vec2 p, float n) {
    float a = atan(p.y, p.x);
    float slice = TAU / max(n, 2.0);
    a = abs(mod(a + 0.5 * slice, slice) - 0.5 * slice);
    return length(p) * vec2(cos(a), sin(a));
}

vec2 foldField(vec2 p, float t) {
    for (int i = 0; i < 6; ++i) {
        float fi = float(i);
        p = abs(p) - vec2(0.34 + 0.05 * sin(t + fi), 0.28 + 0.04 * cos(t * 0.7 - fi));
        p *= rot(SPIN + 0.08 * sin(t * 0.3 + fi * 1.7));
        p *= FOLD_SCALE - 0.055 * fi + amp_low * 0.08;
    }
    return p;
}

vec2 styleWarp(vec2 p, float t) {
    float r = max(length(p), 0.001);
    float a = atan(p.y, p.x);
    if (STYLE == 0) p += 0.13 * vec2(sin(p.y * 9.0 + t), cos(p.x * 7.0 - t));
    else if (STYLE == 1) p = vec2(a / TAU + t * 0.05, 0.18 / r + t * 0.08);
    else if (STYLE == 2) p = vec2(max(abs(p.x), abs(p.y)), min(abs(p.x), abs(p.y))) * sign(p);
    else if (STYLE == 3) p *= 1.0 + 0.24 * sin(a * 6.0 - t * 1.4);
    else if (STYLE == 4) p += 0.10 * sin(p.yx * 11.0 + vec2(t, -t));
    else if (STYLE == 5) p = abs(fract(p * 2.2 + 0.5) - 0.5) * 1.4;
    else if (STYLE == 6) p *= rot(WARP / r + t * 0.17);
    else if (STYLE == 7) p = vec2(log(r) * 0.34 - t * 0.08, a / TAU);
    else if (STYLE == 8) p += normalize(p + vec2(0.001)) * sin(r * 18.0 - t * 3.0) * 0.12;
    else if (STYLE == 9) p.x += floor(p.y * 18.0 + t * 3.0) * 0.018 * sin(t);
    else if (STYLE == 10) p *= 0.78 + 0.22 * cos(a * 8.0 + t * 1.5);
    else if (STYLE == 11) p += vec2(sin(p.y * 15.0), sin(p.x * 13.0)) * 0.08;
    else if (STYLE == 12) p = fract(p * (1.5 + 0.2 * sin(t)) + 0.5) - 0.5;
    else if (STYLE == 13) p *= rot(t * 0.25 + r * 3.0); 
    else if (STYLE == 14) p += 0.12 * vec2(sin(r * 14.0 - t), cos(r * 12.0 + t));
    else if (STYLE == 15) p = abs(p * rot(a + t * 0.1)) - 0.24;
    else if (STYLE == 16) p *= 0.65 + 0.35 * sin(a * 5.0 - r * 8.0 + t);
    else if (STYLE == 17) p += step(0.82, fract(p.y * 9.0 + t)) * vec2(sin(t * 7.0) * 0.12, 0.0);
    else if (STYLE == 18) p *= rot(r * 5.0 - t * 0.35);
    else if (STYLE == 19) p += normalize(p + vec2(0.001)) * sin(r * 25.0 - t * 2.0) * 0.07;
    else if (STYLE == 20) p = normalize(p + vec2(0.001)) * (0.16 / r + fract(r * 4.0 - t * 0.1));
    else if (STYLE == 21) p = abs(fract(p * vec2(3.0, 1.75) + 0.5) - 0.5);
    else if (STYLE == 22) p = sign(p) * pow(abs(p) + vec2(0.001), vec2(0.72));
    else if (STYLE == 23) p *= 0.75 + 0.25 * cos(a * 7.0 + sin(r * 10.0) - t);
    else p = abs(fract(p * 2.0 + vec2(t * 0.03, -t * 0.02) + 0.5) - 0.5);
    return p;
}

vec3 sampleSplit(vec2 uv, vec2 dir, float amount) {
    vec2 px = vec2(1.0 / max(iResolution.x, 1.0), 1.0 / max(iResolution.y, 1.0));
    vec2 d = dir * px * amount;
    return vec3(texture(samp, fract(uv + d)).r,
                texture(samp, fract(uv)).g,
                texture(samp, fract(uv - d)).b);
}

void main() {
    float aspect = iResolution.x / max(iResolution.y, 1.0);
    vec2 center = iMouse.z > 0.5 ? iMouse.xy / iResolution : vec2(0.5);
    vec2 p = (tc - center) * vec2(aspect, 1.0);
    float t = time_f;
    float bass = clamp(amp_low, 0.0, 1.0);
    float mids = clamp(amp_mid, 0.0, 1.0);
    float highs = clamp(amp_high, 0.0, 1.0);

    p *= rot(t * SPIN * (0.35 + bass * 0.35));
    p = kaleido(p, SEGMENTS + floor(mids * 4.0));
    p = styleWarp(p, t);
    vec2 f = foldField(p, t * 0.32);
    float radius = length(f) + 0.0001;
    float angle = atan(f.y, f.x);
    float logBand = fract(log(radius) * (1.8 + WARP) - t * (0.18 + bass * 0.16));
    vec2 wrapped = vec2(cos(angle + logBand * WARP), sin(angle + logBand * WARP));
    wrapped *= exp2(logBand * 1.35 - 1.1);

    vec2 uv = fract(wrapped / vec2(aspect, 1.0) + center);
    vec2 direction = normalize(wrapped + vec2(0.0001));
    vec3 split = sampleSplit(uv, direction, 1.5 + highs * 7.0);
    vec3 source = texture(samp, tc).rgb;

    float ring = 0.5 + 0.5 * sin(log(radius) * (9.0 + float(STYLE % 6)) + t * 1.4);
    float edge = exp(-7.0 * abs(fract(logBand * 4.0) - 0.5));
    float hue = fract(angle / TAU + t * 0.035 * HUE_RATE + logBand * 0.45 + float(STYLE) * 0.047);
    vec3 palette = hsv2rgb(vec3(hue, 0.72 + highs * 0.25, 0.72 + ring * 0.35));
    vec3 fractalCol = split * mix(vec3(1.0), palette, 0.58) * (0.72 + 0.38 * ring);
    fractalCol += palette * edge * (0.10 + amp_peak * 0.22);

    vec3 outCol = mix(source, fractalCol, TEX_MIX);
    outCol += max(outCol - 0.58, 0.0) * (0.24 + amp_smooth * 0.18);
    float vignette = 1.0 - smoothstep(0.55, 1.35, length((tc - center) * vec2(aspect, 1.0)));
    outCol *= 0.78 + 0.22 * vignette;
    outCol *= 1.0 + clamp(amp_peak, 0.0, 1.0) * 0.35;
    outCol = mix(outCol, outCol * vec3(1.0 + bass * 0.30, 1.0 + mids * 0.12, 1.0 + highs * 0.26), 0.65);
    outCol = outCol / (1.0 + max(outCol - 1.0, 0.0));

    color = vec4(clamp(outCol, 0.0, 1.0), texture(samp, tc).a);
}

