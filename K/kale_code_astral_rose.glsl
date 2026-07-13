#version 330 core
// kale_code_astral_rose
// Nested multi-domain kaleidoscope with recursive folds and chromatic refraction.

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform vec2 iResolution;
uniform float time_f;
uniform float amp;
uniform float amp_low;
uniform float amp_mid;
uniform float amp_high;
uniform float amp_peak;
uniform float amp_smooth;
uniform float amp_rms;

const float PI = 3.14159265359;
const float TAU = 6.28318530718;
const int STYLE = 0;
const float SEGMENTS_A = 7.0;
const float SEGMENTS_B = 11.0;
const float FOLD_ZOOM = 1.42;
const float WARP = 0.18;

mat2 rotate2D(float a) {
    float s = sin(a);
    float c = cos(a);
    return mat2(c, -s, s, c);
}

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 345.45));
    p += dot(p, p + 34.345);
    return fract(p.x * p.y);
}

vec3 spectralPalette(float t) {
    vec3 phase = vec3(0.00, 0.18, 0.44);
    return 0.52 + 0.48 * cos(TAU * (t + phase));
}

vec2 kaleidoscope(vec2 p, float segments, float spin, float spiral) {
    float radius = length(p);
    float angle = atan(p.y, p.x) + spin + radius * spiral;
    float sector = TAU / segments;
    angle = abs(mod(angle + sector * 0.5, sector) - sector * 0.5);
    return radius * vec2(cos(angle), sin(angle));
}

vec2 recursiveFold(vec2 p, float t, float drive) {
    for (int i = 0; i < 6; ++i) {
        float fi = float(i);
        p = rotate2D(0.37 + 0.13 * fi + sin(t * 0.19 + fi) * 0.08) * p;
        p = abs(p);
        p -= vec2(0.42 + 0.06 * sin(t * 0.31 + fi * 1.7), 0.31 + 0.05 * cos(t * 0.27 - fi));
        float denominator = max(dot(p, p), 0.16 + 0.025 * fi);
        p = p * (FOLD_ZOOM + drive * 0.18) / denominator - vec2(0.36, 0.27);
    }
    return p;
}

vec2 styleWarp(vec2 p, float radius, float angle, float t, float drive) {
    if (STYLE == 0) {
        p += 0.18 * vec2(cos(angle * 7.0 + t), sin(radius * 14.0 - t));
    } else if (STYLE == 1) {
        p *= 0.78 + 0.28 * cos(angle * 9.0 + radius * 8.0 - t);
        p += normalize(p + 0.001) * sin(radius * 24.0 - t * 2.0) * 0.08;
    } else if (STYLE == 2) {
        p += sin(p.yx * vec2(13.0, 17.0) + t * vec2(0.7, -0.9)) * 0.09;
    } else if (STYLE == 3) {
        p = mix(p, p / max(dot(p, p), 0.22), 0.32 + 0.12 * sin(t));
    } else if (STYLE == 4) {
        p += vec2(sin(angle * 12.0), cos(angle * 5.0)) * (0.05 + radius * 0.06);
    } else if (STYLE == 5) {
        p = rotate2D(sin(radius * 9.0 - t) * 0.7) * p;
        p.y += sin(abs(p.x) * 18.0 + t * 1.7) * 0.08;
    } else if (STYLE == 6) {
        p = abs(p * 1.18) - vec2(0.31, 0.19);
        p.x += sin(p.y * 21.0 + t) * 0.06;
    } else if (STYLE == 7) {
        p = vec2(p.x * p.x - p.y * p.y, 2.0 * p.x * p.y) * 0.72;
        p += vec2(cos(t * 0.43), sin(t * 0.37)) * 0.11;
    } else if (STYLE == 8) {
        p += normalize(p + 0.001) * cos(angle * 11.0 - radius * 18.0 + t) * 0.12;
    } else if (STYLE == 9) {
        p += vec2(sin(p.y * 15.0 + t), sin(p.x * 19.0 - t * 0.8)) * 0.11;
        p = rotate2D(length(p) * 1.4) * p;
    } else if (STYLE == 10) {
        p *= 1.0 + 0.22 * sin(angle * 13.0 + t) * cos(radius * 9.0 - t);
    } else if (STYLE == 11) {
        p = abs(rotate2D(PI * 0.25) * p);
        p -= min(p.x, p.y) * 0.35;
    } else if (STYLE == 12) {
        p += vec2(cos(p.y * 26.0 - t), sin(p.x * 22.0 + t)) * 0.055;
        p /= 0.84 + 0.16 * cos(radius * 31.0);
    } else if (STYLE == 13) {
        p = rotate2D(floor(radius * 8.0) * PI * 0.125 + t * 0.08) * p;
        p += sign(p) * 0.04 * sin(angle * 14.0);
    } else {
        p += vec2(cos(angle * 7.0 + radius * 20.0), sin(angle * 9.0 - radius * 17.0)) * 0.10;
        p = mix(p, abs(p.yx) - 0.24, 0.28 + drive * 0.12);
    }
    return p * (1.0 + WARP * drive);
}

vec2 mirrorTile(vec2 uv) {
    return 1.0 - abs(1.0 - 2.0 * fract(uv * 0.5 + 0.5));
}

vec3 refractedTexture(vec2 uv, vec2 direction, float amount) {
    vec2 safeUV = mirrorTile(uv);
    vec2 offset = direction * amount;
    vec3 texel;
    texel.r = texture(samp, mirrorTile(safeUV + offset)).r;
    texel.g = texture(samp, safeUV).g;
    texel.b = texture(samp, mirrorTile(safeUV - offset)).b;
    return texel;
}

float filigree(vec2 p, float radius, float angle, float t) {
    float angular = abs(sin(angle * (SEGMENTS_A * 0.5) + t * 0.7));
    float radial = abs(sin(radius * (19.0 + float(STYLE)) - t * 1.8));
    float weave = abs(sin((p.x + p.y) * 15.0 + t) * cos((p.x - p.y) * 13.0 - t));
    float lineA = 1.0 - smoothstep(0.025, 0.12, abs(angular - radial));
    float lineB = 1.0 - smoothstep(0.02, 0.10, abs(weave - 0.52));
    return max(lineA, lineB * 0.72);
}

void main() {
    float aspect = iResolution.x / max(iResolution.y, 1.0);
    float low = clamp(max(amp_low, amp * 0.65), 0.0, 1.5);
    float mid = clamp(max(amp_mid, amp_smooth), 0.0, 1.5);
    float high = clamp(max(amp_high, amp_rms), 0.0, 1.5);
    float peak = clamp(amp_peak, 0.0, 1.5);
    float drive = low * 0.34 + mid * 0.31 + high * 0.22 + peak * 0.13;
    float t = time_f * (0.24 + 0.04 * float(STYLE % 5));

    vec2 p = (tc - 0.5) * vec2(aspect, 1.0) * 2.0;
    float radius = length(p);
    float angle = atan(p.y, p.x);

    vec2 domainA = kaleidoscope(p, SEGMENTS_A + floor(low * 3.0), t * 0.41, 0.8 + mid * 1.5);
    domainA = styleWarp(domainA, radius, angle, t, drive);
    vec2 fold = recursiveFold(domainA * 0.72, t, drive);
    domainA += fold * (0.065 + 0.025 * high);

    vec2 domainB = kaleidoscope(rotate2D(-t * 0.27) * p.yx, SEGMENTS_B + floor(high * 2.0),
                                -t * 0.33, -1.1 - low);
    domainB = styleWarp(domainB, radius, -angle, -t * 0.73, high);
    domainB += sin(domainB.yx * (8.0 + float(STYLE)) + t) * 0.055;

    vec2 domainC = kaleidoscope(p / max(radius * 0.38 + 0.72, 0.2), SEGMENTS_A + SEGMENTS_B,
                                t * 0.16, sin(t * 0.4) * 2.2);
    domainC = recursiveFold(domainC * 0.43, -t * 0.61, mid) * 0.42;

    vec2 uvA = tc + domainA / vec2(aspect, 1.0) * 0.29;
    vec2 uvB = 0.5 + domainB / vec2(aspect, 1.0) * 0.41;
    vec2 uvC = tc.yx + domainC / vec2(1.0, aspect) * 0.33;
    vec2 tangent = normalize(vec2(-p.y, p.x) + 0.001);

    vec3 layerA = refractedTexture(uvA, tangent, 0.006 + high * 0.018);
    vec3 layerB = refractedTexture(uvB, normalize(domainB + 0.001), 0.004 + peak * 0.022);
    vec3 layerC = refractedTexture(uvC, normalize(fold + 0.001), 0.003 + mid * 0.013);

    float interference =
        0.5 + 0.5 * sin(dot(domainA, domainB) * 17.0 + length(fold) * 8.0 - t * 2.3);
    float petals = 0.5 + 0.5 * cos(angle * SEGMENTS_A + sin(radius * 11.0 - t) * 2.4);
    float lace = filigree(domainA + domainB * 0.35, radius, angle, t);
    float cell = 1.0 - smoothstep(0.12, 0.48, abs(sin(fold.x * 8.0) * cos(fold.y * 9.0)));

    vec3 paletteA = spectralPalette(radius * 0.32 + interference * 0.19 + t * 0.035);
    vec3 paletteB = spectralPalette(petals * 0.27 - length(domainB) * 0.11 - t * 0.025);
    vec3 base = mix(layerA, layerB, 0.28 + 0.36 * interference);
    base = mix(base, layerC, 0.18 + 0.24 * petals);
    base *= mix(vec3(1.0), paletteA * 1.45, 0.37 + 0.22 * mid);
    base += paletteB * lace * (0.11 + 0.16 * peak);
    base += paletteA * cell * interference * (0.07 + 0.10 * high);

    float halo = exp(-2.7 * abs(radius - (0.36 + 0.12 * sin(t + angle * 3.0))));
    base += spectralPalette(angle / TAU + t * 0.04) * halo * (0.10 + low * 0.14);
    base *= 0.86 + 0.24 * drive;
    base = pow(max(base, vec3(0.0)), vec3(0.86));
    base = mix(base, base / (base + vec3(0.42)), 0.42);
    base = mix(base, vec3(1.0) - base, smoothstep(0.90, 1.25, peak) * 0.32);

    color = vec4(clamp(base, 0.0, 1.0), 1.0);
}
