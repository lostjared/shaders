#version 330 core
// pilot_effect_ant_bloom.glsl
// Diversified pilot shader: frac/mirror/gem/ant + library-inspired prism/ripple/glitch/VHS/grid behaviors.
// Inspired motif source: 3high.glsl
// Random donor shader: material_strange.glsl

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform sampler1D spectrum;
uniform vec2 iResolution;
uniform float time_f;
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
const int FAMILY = 6;
const float SEED_A = 0.8300;
const float SEED_B = 1.4900;
const float SEED_C = 2.1700;
const vec3 BASE_TINT = vec3(0.7660, 0.9050, 0.7705);
const float INSP_1 = 0.4692;
const float INSP_2 = 0.7732;
const float INSP_3 = 0.9257;
const float INSP_MODE = 0.0000;
const int CAT_ID = 0;
const int VAR_ID = 0;
const float CAT_SPIN = 0.0909;
const float CAT_WARP = 0.0909;
const float CAT_SAT = 0.3500;
const float VAR_PULSE = 0.2000;
const float VAR_GRID = 0.6862;
const float VAR_STYLE = 0.8759;
const float DONOR_A = 0.1307;
const float DONOR_B = 0.3252;
const float DONOR_C = 0.3062;
const float DONOR_D = 0.5167;
const float DONOR_MODE = 0.9333;

float hash11(float p) {
    p = fract(p * 0.1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

float hash21(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.11369, 0.13787));
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

mat2 rot(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c);
}

vec2 mirrorTile(vec2 uv) {
    // Mirror with 2.0-period so folds occur at integer boundaries, not at 0.5.
    vec2 m = mod(uv, 2.0);
    vec2 tri = 1.0 - abs(m - 1.0);
    vec2 px = 1.0 / max(iResolution, vec2(1.0));
    return clamp(tri, px * 1.5, 1.0 - px * 1.5);
}

vec2 kaleido(vec2 p, float seg) {
    seg = max(seg, 2.0);
    float a = atan(p.y, p.x);
    float r = length(p);
    float k = TAU / seg;
    a = mod(a, k);
    a = abs(a - 0.5 * k);
    return vec2(cos(a), sin(a)) * r;
}

vec3 palette(float t) {
    vec3 a = vec3(0.5);
    vec3 b = vec3(0.5);
    vec3 c = vec3(1.0);
    vec3 d = vec3(SEED_A, SEED_B, SEED_C);
    return a + b * cos(TAU * (c * t + d));
}

float safeSpec(float x, float fallback, float reactive) {
    if (reactive < 0.5)
        return fallback;
    return texture(spectrum, clamp(x, 0.0, 1.0)).r;
}

vec3 chromaSplit(vec2 uv, vec2 dir, float amt) {
    vec2 o = dir * amt;
    vec2 u0 = mirrorTile(uv + o);
    vec2 u1 = mirrorTile(uv);
    vec2 u2 = mirrorTile(uv - o);
    float r = texture(samp, u0).r;
    float g = texture(samp, u1).g;
    float b = texture(samp, u2).b;
    return vec3(r, g, b);
}

void main(void) {
    float sense = clamp(amp_peak + amp_rms + amp_smooth + amp_low + amp_mid + amp_high + abs(iamp) * 0.001, 0.0, 1.0);
    float reactive = step(0.002, sense);

    float a = mix(0.15, clamp(amp, 0.0, 1.0), reactive);
    float aPk = mix(0.12, clamp(amp_peak, 0.0, 1.0), reactive);
    float aRms = mix(0.14, clamp(amp_rms, 0.0, 1.0), reactive);
    float aSm = mix(0.18, clamp(amp_smooth, 0.0, 1.0), reactive);
    float aLo = mix(0.16, clamp(amp_low, 0.0, 1.0), reactive);
    float aMi = mix(0.14, clamp(amp_mid, 0.0, 1.0), reactive);
    float aHi = mix(0.12, clamp(amp_high, 0.0, 1.0), reactive);

    float sBass = safeSpec(0.04, 0.17 + 0.09 * sin(time_f * 0.7 + SEED_A), reactive);
    float sLo = safeSpec(0.13, 0.15 + 0.10 * sin(time_f * 0.9 + SEED_B), reactive);
    float sMi = safeSpec(0.30, 0.14 + 0.10 * sin(time_f * 1.1 + SEED_C), reactive);
    float sHi = safeSpec(0.62, 0.13 + 0.09 * sin(time_f * 1.3 + SEED_B), reactive);
    float sAir = safeSpec(0.86, 0.11 + 0.08 * sin(time_f * 1.5 + SEED_A), reactive);

    float aspect = iResolution.x / max(iResolution.y, 1.0);
    vec2 uv = tc;
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    float r = max(length(p), 1e-4);
    float ang = atan(p.y, p.x);
    float t = time_f;
    float t2 = t * (0.85 + 0.45 * INSP_1) + TAU * INSP_2;

    // Category profile warp: gives each theme a distinct spatial signature.
    vec2 pWarp = p;
    pWarp = rot((0.18 + 0.55 * CAT_SPIN) * t2 + CAT_WARP * TAU * 0.15) * pWarp;
    pWarp += vec2(
                 sin((p.y + CAT_WARP) * (3.0 + 7.0 * VAR_PULSE) + t2 * (0.5 + CAT_SPIN)),
                 cos((p.x - CAT_WARP) * (3.5 + 8.0 * VAR_GRID) - t2 * (0.45 + CAT_SPIN))) *
             (0.01 + 0.03 * CAT_WARP);
    p = mix(p, pWarp, 0.30 + 0.45 * INSP_3);
    r = max(length(p), 1e-4);
    ang = atan(p.y, p.x);

    vec2 uvFx = uv;
    vec3 fxCol = texture(samp, uv).rgb;
    float fxGlow = 0.0;

    if (FAMILY == 0) {
        // Fractal mirror pulse tunnel
        vec2 q = p;
        q = kaleido(q, 5.0 + 8.0 * sMi + 3.0 * aMi);
        for (int i = 0; i < 5; i++) {
            float fi = float(i);
            q = rot(t * (0.2 + 0.07 * fi) + fi + sHi * 2.0) * q;
            q = abs(q * (1.35 + 0.1 * fi + 0.45 * sLo)) - (0.55 + 0.08 * sin(t2 + fi));
        }
        uvFx = mirrorTile(0.5 + q / vec2(aspect, 1.0));
        fxCol = chromaSplit(uvFx, normalize(q + 1e-4), 0.003 + 0.02 * sHi + 0.01 * aPk);
        fxGlow = exp(-1.8 * length(q)) * (0.25 + 0.8 * sBass);
    } else if (FAMILY == 1) {
        // Prism glass split
        vec2 q = p;
        q = rot(0.4 * t + sMi) * q;
        float tri = max(abs(q.x), abs(q.y * 1.2 + q.x * 0.35));
        vec2 dir = normalize(q + vec2(0.001));
        float disp = 0.008 + 0.05 * sHi + 0.02 * aPk;
        uvFx = mirrorTile(uv + dir * (tri * 0.06 + 0.03 * aMi));
        fxCol = chromaSplit(uvFx, dir, disp);
        fxCol += palette(tri * 2.3 + t * 0.2 + sAir) * (0.08 + 0.2 * (1.0 - smoothstep(0.15, 0.8, tri)));
        fxGlow = (0.1 + 0.5 * aSm) * exp(-2.5 * tri);
    } else if (FAMILY == 2) {
        // Ripple amp fluid
        vec2 q = p;
        float w1 = sin(r * (26.0 + 20.0 * sBass) - t * (4.0 + 3.0 * aLo));
        float w2 = cos((q.x + q.y) * (16.0 + 10.0 * sMi) + t * (3.0 + 2.0 * aHi));
        vec2 off = vec2(w1, w2) * (0.015 + 0.03 * aMi + 0.02 * sLo);
        uvFx = mirrorTile(uv + off);
        fxCol = texture(samp, uvFx).rgb;
        fxCol = mix(fxCol, fxCol.brg, 0.2 + 0.45 * sHi);
        fxGlow = 0.15 + 0.35 * smoothstep(0.0, 1.0, 0.5 + 0.5 * w1);
    } else if (FAMILY == 3) {
        // VHS + glitch damage
        vec2 q = uv;
        float line = floor(q.y * iResolution.y * 0.35);
        float n = hash21(vec2(line, floor(t * 18.0 + SEED_A)));
        q.x += (n - 0.5) * (0.02 + 0.07 * aPk);
        q.y += sin(t2 * 2.0 + q.x * 25.0) * (0.004 + 0.02 * aLo);
        vec3 split = chromaSplit(mirrorTile(q), vec2(1.0, 0.0), 0.002 + 0.01 * sHi);
        float scan = 0.95 - 0.16 * sin(uv.y * iResolution.y * 1.35);
        float drop = step(0.992, hash21(vec2(floor(uv.y * 180.0), floor(t * 0.8 + SEED_B))));
        fxCol = split * scan + drop * vec3(0.2, 0.07, 0.05);
        fxGlow = 0.07 + 0.18 * aRms;
    } else if (FAMILY == 4) {
        // Grid neon / moire
        vec2 q = p * (2.0 + 2.5 * sMi);
        q = rot(0.25 * t + 0.8 * aSm) * q;
        vec2 g = abs(fract(q) - 0.5);
        float grid = smoothstep(0.08, 0.0, min(g.x, g.y));
        float moire = 0.5 + 0.5 * sin((q.x * q.y) * (6.0 + 4.0 * sAir) + t * 2.5);
        uvFx = mirrorTile(uv + vec2(moire, grid) * (0.01 + 0.03 * aMi));
        fxCol = texture(samp, uvFx).rgb;
        fxCol += palette(moire + t * 0.12) * grid * (0.25 + 0.4 * aPk);
        fxGlow = grid * (0.2 + 0.4 * sHi);
    } else if (FAMILY == 5) {
        // Diamond shatter facets
        vec2 q = p;
        q = abs(q);
        if (q.y > q.x)
            q = q.yx;
        float facet = q.x + q.y * 0.35;
        float crack = sin(facet * (30.0 + 20.0 * sHi) - t * (4.0 + 3.0 * aPk));
        vec2 dir = normalize(vec2(q.x + 1e-3, q.y + 1e-3));
        uvFx = mirrorTile(uv + dir * crack * (0.015 + 0.02 * aMi));
        fxCol = chromaSplit(uvFx, dir, 0.002 + 0.02 * sHi);
        fxCol = mix(fxCol, palette(facet * 1.6 + t * 0.15), 0.22 + 0.35 * aSm);
        fxGlow = (0.12 + 0.35 * sBass) * smoothstep(0.8, 0.1, facet);
    } else if (FAMILY == 6) {
        // Bubble fisheye lens
        vec2 q = p;
        float lens = 1.0 / (1.0 + (1.7 + 2.0 * sBass) * dot(q, q));
        q *= (1.2 - 0.7 * lens);
        q += 0.08 * vec2(sin(t * 1.4 + q.y * 8.0), cos(t * 1.2 + q.x * 8.0)) * (0.4 + aLo);
        uvFx = mirrorTile(0.5 + q / vec2(aspect, 1.0));
        fxCol = texture(samp, uvFx).rgb;
        fxCol += palette(lens + t * 0.1 + sAir) * (0.1 + 0.3 * lens * aSm);
        fxGlow = lens * (0.2 + 0.5 * aPk);
    } else if (FAMILY == 7) {
        // Vortex / log-polar tunnel
        float lp = log(r + 1e-3);
        float spin = ang + t * (0.8 + 1.8 * aSm) + sin(lp * 5.0 + t) * (0.4 + sMi);
        float rr = fract(lp * (1.1 + 0.8 * sBass) - t * (0.2 + 0.6 * aLo));
        vec2 q = vec2(cos(spin), sin(spin)) * rr;
        uvFx = mirrorTile(0.5 + q * vec2(0.8, 1.0));
        fxCol = chromaSplit(uvFx, normalize(q + 1e-4), 0.002 + 0.015 * sHi);
        fxGlow = (0.1 + 0.5 * sBass) * smoothstep(1.0, 0.0, rr);
    } else if (FAMILY == 8) {
        // Mosaic + pseudo pixel-sort drift
        float px = 90.0 + 280.0 * (0.2 + aLo);
        vec2 cell = floor(uv * px) / px;
        float drift = hash21(vec2(cell.y * 300.0, floor(t * (6.0 + 10.0 * aPk)))) - 0.5;
        cell.x += drift * (0.02 + 0.06 * aMi);
        vec3 c0 = texture(samp, mirrorTile(cell)).rgb;
        vec3 c1 = texture(samp, mirrorTile(cell + vec2(0.002 + 0.01 * sHi, 0.0))).rgb;
        float gate = smoothstep(0.35, 0.75, c0.g + sMi * 0.35);
        fxCol = mix(c0, c1.bgr, gate);
        fxGlow = gate * (0.08 + 0.28 * aRms);
    } else if (FAMILY == 9) {
        // Plasma xor / synth math blend
        vec2 q = p * (2.2 + 1.8 * sLo);
        float a1 = sin(q.x * 7.0 + t * 1.7 + sBass * 5.0);
        float a2 = cos(q.y * 8.0 - t * 1.3 + sMi * 4.0);
        float a3 = sin((q.x + q.y) * 6.0 + t * 2.1);
        float m = 0.5 + 0.5 * sin((a1 + a2 + a3) * (2.0 + aHi * 3.0));
        uvFx = mirrorTile(uv + vec2(a1, a2) * (0.01 + 0.03 * aMi));
        fxCol = mix(texture(samp, uvFx).rgb, palette(m + t * 0.07), 0.35 + 0.35 * aSm);
        fxGlow = 0.1 + 0.4 * m * aPk;
    } else if (FAMILY == 10) {
        // Echo trails (multi-tap)
        vec2 q = p;
        vec2 dir = normalize(vec2(cos(ang + t), sin(ang - t)) + 1e-4);
        vec3 acc = vec3(0.0);
        float wsum = 0.0;
        for (int i = 0; i < 5; i++) {
            float fi = float(i);
            float w = 1.0 / (1.0 + fi * 0.9);
            vec2 u = mirrorTile(uv + dir * (0.006 + 0.02 * aSm) * fi + vec2(0.0, sin(t2 + fi) * 0.002));
            acc += texture(samp, u).rgb * w;
            wsum += w;
        }
        fxCol = acc / max(wsum, 1e-4);
        fxCol = mix(fxCol, palette(r * 1.8 + t * 0.1), 0.18 + 0.32 * sAir);
        fxGlow = 0.1 + 0.25 * aRms;
    } else {
        // Ant web / gem spoke hybrid
        vec2 q = p;
        float spokeCount = max(1.0, floor(10.0 + 8.0 * sHi + 0.5));
        float spoke = sin(ang * spokeCount + t * (2.0 + 2.5 * aHi));
        float web = sin((q.x + q.y) * (24.0 + 16.0 * sLo) - t * (3.0 + 2.0 * aLo));
        float fold = sin((abs(q.x) - abs(q.y)) * (15.0 + 12.0 * sMi) + t * 1.8);
        vec2 off = vec2(spoke + fold, web - fold) * (0.01 + 0.03 * aMi);
        uvFx = mirrorTile(uv + off);
        fxCol = texture(samp, uvFx).rgb;
        fxCol += palette(spoke * 0.5 + web * 0.35 + t * 0.1) * (0.12 + 0.35 * aPk);
        fxGlow = 0.1 + 0.4 * smoothstep(0.2, 1.0, abs(spoke * web));
    }

    vec3 col = fxCol * BASE_TINT;
    vec3 accent = palette(r * 1.7 + (0.5 + 0.5 * sin(ang)) * 0.3 + t * 0.08 + sAir);
    col = mix(col, col.brg, 0.15 + 0.35 * sHi);
    col += accent * (0.05 + 0.18 * aSm + 0.2 * fxGlow);

    // Per-shader inspiration blend adds variation while staying seam-safe.
    vec2 inspOff = vec2(
                       sin((uv.y + INSP_1) * (8.0 + 12.0 * INSP_2) + t2 * (0.6 + INSP_3)),
                       cos((uv.x + INSP_2) * (7.0 + 11.0 * INSP_1) - t2 * (0.5 + INSP_2))) *
                   (0.004 + 0.02 * aSm + 0.01 * sHi);
    vec3 inspTex = texture(samp, mirrorTile(uv + inspOff)).rgb;
    float inspMix = 0.12 + 0.32 * INSP_3 + 0.18 * aRms;
    if (INSP_MODE < 0.33) {
        col = mix(col, inspTex.bgr, inspMix);
    } else if (INSP_MODE < 0.66) {
        vec3 inspWarp = mix(inspTex.gbr, inspTex.rgb, 0.5 + 0.5 * sin(t2 + INSP_2 * TAU));
        col = mix(col, inspWarp, inspMix * (0.8 + 0.2 * sAir));
    } else {
        col += (inspTex - vec3(0.5)) * (0.18 + 0.35 * inspMix);
    }

    int ringCount = 2 + int(mod(float(VAR_ID + CAT_ID), 7.0));
    float angWave = 0.5 + 0.5 * sin(float(ringCount) * ang + t2 * (0.25 + 0.9 * CAT_SPIN));
    vec3 catTone = palette(CAT_WARP + angWave * (0.25 + 0.45 * VAR_PULSE) + t2 * (0.04 + 0.08 * CAT_SAT));
    col = mix(col, catTone, 0.10 + 0.30 * CAT_SAT * (0.35 + 0.65 * fxGlow));

    if (VAR_STYLE < 0.33) {
        col = mix(col, col.gbr, 0.08 + 0.22 * VAR_GRID);
    } else if (VAR_STYLE < 0.66) {
        float stripe = 0.5 + 0.5 * sin((p.x - p.y) * (8.0 + 22.0 * VAR_GRID) + t2);
        col *= 0.88 + 0.22 * stripe;
    } else {
        float halo = exp(-(2.0 + 3.0 * VAR_PULSE) * r);
        col += catTone * (0.06 + 0.24 * halo);
    }

    // Random donor fusion: this pilot blends with one random external shader signature.
    vec2 donorUV = uv + vec2(
                            sin((uv.y + DONOR_A) * (5.0 + 18.0 * DONOR_B) + t2 * (0.7 + DONOR_C)),
                            cos((uv.x + DONOR_C) * (6.0 + 16.0 * DONOR_D) - t2 * (0.6 + DONOR_A))) *
                            (0.004 + 0.022 * aSm + 0.015 * aPk);
    donorUV = mirrorTile(donorUV);
    vec3 donorCol = texture(samp, donorUV).rgb;
    float donorMask = 0.5 + 0.5 * sin((p.x + p.y) * (8.0 + 20.0 * DONOR_B) + t2 * (0.8 + DONOR_D));
    if (DONOR_MODE < 0.25) {
        col = mix(col, donorCol, (0.08 + 0.30 * DONOR_A) * donorMask);
    } else if (DONOR_MODE < 0.50) {
        col += (donorCol - vec3(0.5)) * (0.10 + 0.28 * DONOR_C) * (0.7 + 0.3 * donorMask);
    } else if (DONOR_MODE < 0.75) {
        vec3 donorShift = vec3(donorCol.r, donorCol.b, donorCol.g);
        col = mix(col, donorShift, (0.10 + 0.24 * DONOR_D) * (0.6 + 0.4 * donorMask));
    } else {
        float donorHalo = exp(-(2.0 + 4.0 * DONOR_A) * r);
        col = mix(col, col * donorCol * 1.8, (0.10 + 0.20 * DONOR_B) * (0.5 + 0.5 * donorHalo));
    }

    float vign = 1.0 - smoothstep(0.55, 1.25, length(p));
    col *= mix(0.72, 1.18, vign);

    col *= 1.0 + 0.35 * aPk + 0.25 * sBass;
    col = pow(max(col, 0.0), vec3(0.96 - 0.2 * aSm));
    col = clamp(col, 0.0, 1.0);

    color = vec4(col, 1.0);
}
