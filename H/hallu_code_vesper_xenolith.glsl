#version 330 core

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform vec4 iMouse;

// Audio
uniform sampler1D spectrum;
uniform float amp_peak;
uniform float amp_smooth;
uniform float amp_low;
uniform float amp_mid;
uniform float amp_high;

out vec4 color;
in vec2 tc;

const float PI = 3.14159265359;
const float TAU = 6.28318530718;
const float iBrightness = 1.05;
const float iContrast = 1.18;
const float iSaturation = 1.30;

mat2 rot(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c);
}

vec2 wrapUV(vec2 uv) {
    return 1.0 - abs(1.0 - 2.0 * fract(uv * 0.5));
}

vec3 sampleMirror(vec2 uv) {
    vec2 size = vec2(textureSize(samp, 0));
    vec2 edge = 0.5 / size;
    vec2 wrapped = clamp(wrapUV(uv), edge, 1.0 - edge);
    return textureLod(samp, wrapped, 0.0).rgb;
}

float hash21(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec2 hash22(vec2 p) {
    float n = hash21(p);
    return fract(vec2(n, n * 1.2154 + 0.3719));
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), u.x),
               mix(hash21(i + vec2(0.0, 1.0)), hash21(i + 1.0), u.x), u.y);
}

float fbm(vec2 p) {
    float value = 0.0;
    float weight = 0.52;
    mat2 octave = mat2(1.63, 1.21, -1.21, 1.63);
    for (int i = 0; i < 6; ++i) {
        value += weight * noise(p);
        p = octave * p + 0.17;
        weight *= 0.50;
    }
    return value;
}

vec2 cellular(vec2 p, float t) {
    vec2 cell = floor(p);
    vec2 local = fract(p);
    float nearest = 10.0;
    float second = 10.0;
    for (int y = -1; y <= 1; ++y) {
        for (int x = -1; x <= 1; ++x) {
            vec2 offset = vec2(float(x), float(y));
            vec2 point = hash22(cell + offset);
            point = 0.5 + 0.38 * sin(t * 0.43 + TAU * point);
            float d = length(offset + point - local);
            if (d < nearest) {
                second = nearest;
                nearest = d;
            } else if (d < second) {
                second = d;
            }
        }
    }
    return vec2(nearest, second - nearest);
}

vec2 kaleido(vec2 p, float segments, float phase) {
    float radius = length(p);
    float angle = atan(p.y, p.x) + phase;
    float sector = TAU / segments;
    angle = abs(mod(angle + sector * 0.5, sector) - sector * 0.5);
    return radius * vec2(cos(angle), sin(angle));
}

vec3 spectralPalette(float t) {
    vec3 base = vec3(0.48, 0.46, 0.52);
    vec3 range = vec3(0.52, 0.49, 0.48);
    vec3 rate = vec3(1.00, 0.83, 1.17);
    vec3 phase = vec3(0.04, 0.31, 0.63);
    return base + range * cos(TAU * (rate * t + phase));
}

vec3 xenolith(vec2 uv, vec2 center, float t, vec3 audio) {
    float aspect = iResolution.x / max(iResolution.y, 1.0);
    vec2 p = (uv - center) * vec2(aspect, 1.0);
    float radius = length(p);
    float angle = atan(p.y, p.x);

    // Nested fluid warping supplies motion underneath the hard crystal folds.
    vec2 q = vec2(fbm(p * 2.15 + vec2(t * 0.18, -t * 0.13)),
                  fbm(p.yx * 2.35 + vec2(5.7, 2.1) - t * 0.15));
    vec2 r = vec2(fbm(p * 3.10 + q * 3.4 + vec2(-t * 0.11, t * 0.16)),
                  fbm(p.yx * 2.85 - q * 3.0 + vec2(9.2, 1.8) + t * 0.12));
    p += (r - 0.5) * (0.20 + audio.x * 0.16);
    p *= rot(0.12 * t + (q.x - q.y) * 0.35);

    float segments = 9.0 + floor(audio.y * 6.0);
    vec2 folded = kaleido(p, segments, 0.08 * t);
    vec2 orbit = folded;
    float edge = 10.0;
    float glow = 0.0;
    float strata = 0.0;
    vec3 texAccum = vec3(0.0);
    float texWeight = 0.0;

    for (int i = 0; i < 7; ++i) {
        float fi = float(i);
        orbit = abs(orbit) - vec2(0.145, 0.105 + 0.018 * sin(t + fi));
        orbit *= rot(0.34 + fi * 0.71 + t * (0.025 + fi * 0.004));
        orbit *= 1.36 + 0.055 * sin(t * 0.29 + fi * 1.7);

        vec2 cell = cellular(orbit * (1.7 + fi * 0.11), t + fi * 1.3);
        edge = min(edge, cell.y / (1.0 + fi * 0.22));
        glow += exp(-22.0 * cell.y) / (1.0 + fi * 0.45);
        strata += sin(length(orbit) * 11.0 - t * 0.7 + fi * 1.9) /
                  (1.0 + fi * 0.75);

        float weight = 1.0 / (1.0 + fi * 0.52);
        vec2 texUV = orbit * (0.22 + fi * 0.012) + 0.5;
        texUV += 0.025 * vec2(sin(t + fi), cos(t * 0.83 - fi));
        texAccum += sampleMirror(texUV) * weight;
        texWeight += weight;
    }
    texAccum /= texWeight;

    float facet = cellular(folded * 8.0 + q * 1.5, t).x;
    float crystalEdge = 1.0 - smoothstep(0.015, 0.085, edge);
    float innerLight = exp(-3.8 * radius) * (0.65 + 0.35 * cos(angle * segments - t));
    float interference = 0.5 + 0.5 * sin(strata * 2.6 + facet * 13.0 + t * 0.38);

    vec3 mineral = spectralPalette(interference * 0.44 + edge * 2.2 + t * 0.025);
    vec3 deep = spectralPalette(radius * 0.25 - q.x * 0.24 + 0.58);
    vec3 col = mix(texAccum * (0.62 + 0.30 * mineral), mineral, 0.34 + 0.20 * r.y);
    col += mineral * crystalEdge * (0.52 + audio.z * 0.85);
    col += deep * glow * 0.095;
    col += vec3(0.76, 0.88, 1.0) * pow(max(interference, 0.0), 9.0) * innerLight * 0.40;

    // A fine spectral rim gives the folded stone a polished, refractive finish.
    float rim = pow(1.0 - clamp(facet, 0.0, 1.0), 5.0);
    col += spectralPalette(angle / TAU + t * 0.04) * rim * 0.16 * (1.0 + audio.z);
    return col;
}

void main() {
    vec2 uv = tc;
    vec2 center = vec2(0.5);
    if (iMouse.z > 0.0) {
        center = iMouse.xy / iResolution;
    }

    float bass = clamp(texture(spectrum, 0.035).r + amp_low * 0.65, 0.0, 2.0);
    float mids = clamp(texture(spectrum, 0.22).r + amp_mid * 0.60, 0.0, 2.0);
    float highs = clamp(texture(spectrum, 0.62).r + amp_high * 0.70, 0.0, 2.0);
    float beat = max(amp_peak, bass);
    float t = time_f * 0.20 * (1.0 + beat * 0.34);

    vec3 col = xenolith(uv, center, t, vec3(bass, mids, highs));

    // Subtle RGB refraction preserves detail from the source at bright edges.
    vec2 fromCenter = uv - center;
    vec2 chroma = fromCenter * (0.0025 + highs * 0.0025);
    col.r = mix(col.r, sampleMirror(uv + chroma).r, 0.12);
    col.b = mix(col.b, sampleMirror(uv - chroma).b, 0.12);

    float luma = dot(col, vec3(0.299, 0.587, 0.114));
    col = mix(vec3(luma), col, iSaturation);
    col = (col - 0.5) * iContrast + 0.5;
    col *= iBrightness * (1.0 + bass * 0.22 + amp_smooth * 0.12);
    col = col / (0.84 + 0.34 * col); // soft highlight compression

    vec2 vignetteUV = uv * (1.0 - uv.yx);
    float vignette = pow(max(vignetteUV.x * vignetteUV.y * 15.5, 0.0), 0.16);
    color = vec4(max(col * vignette, 0.0), 1.0);
}
