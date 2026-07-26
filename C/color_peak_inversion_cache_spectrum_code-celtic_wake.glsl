#version 330 core
// color_peak_inversion_cache_spectrum_code-celtic_wake
// Large-form recursive fold, cyber-blue ripples, and eight-frame FFT feedback
// Left Click: Direct Feedback Center Control
// Right Click: Directional History Stretch

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

uniform float time_f;
uniform vec2 iResolution;
uniform vec4 iMouse;
uniform float amp_peak;
uniform float amp_smooth;

const float PI = 3.14159265358979323846;
const float TAU = 6.28318530717958647692;
const int FOLD_VARIANT = 7;

vec2 mirrorUV(vec2 uv) {
    return 1.0 - abs(fract(uv * 0.5) * 2.0 - 1.0);
}

vec2 rotateUV(vec2 uv, float angle, vec2 center, float aspect) {
    float s = sin(angle), c = cos(angle);
    vec2 p = (uv - center) * vec2(aspect, 1.0);
    p = mat2(c, -s, s, c) * p;
    return p / vec2(aspect, 1.0) + center;
}

vec3 blueTint(float t) {
    // Adapted from blue_dream2: strong blue motion without crushing source detail.
    vec3 dream = vec3(0.05, 0.20, 0.80);
    dream += vec3(0.05, 0.20, 0.60) *
             cos(TAU * (t + vec3(0.50, 0.20, 0.00)));
    return vec3(0.78, 0.86, 0.92) + dream * vec3(0.40, 0.55, 0.24);
}

vec4 sampleCache(int idx, vec2 uv) {
    uv = mirrorUV(uv);
    if (idx == 0) return texture(samp1, uv);
    if (idx == 1) return texture(samp2, uv);
    if (idx == 2) return texture(samp3, uv);
    if (idx == 3) return texture(samp4, uv);
    if (idx == 4) return texture(samp5, uv);
    if (idx == 5) return texture(samp6, uv);
    if (idx == 6) return texture(samp7, uv);
    return texture(samp8, uv);
}

float sampleSpectrumHistory(int idx, float freq) {
    if (idx == 0) return texture(spectrum1, freq).r;
    if (idx == 1) return texture(spectrum2, freq).r;
    if (idx == 2) return texture(spectrum3, freq).r;
    if (idx == 3) return texture(spectrum4, freq).r;
    if (idx == 4) return texture(spectrum5, freq).r;
    if (idx == 5) return texture(spectrum6, freq).r;
    return texture(spectrum7, freq).r;
}

vec3 sampleLiveHQ(vec2 uv) {
    uv = mirrorUV(uv);
    vec2 dx = dFdx(uv);
    vec2 dy = dFdy(uv);
    vec2 px = 1.0 / max(iResolution, vec2(1.0));
    vec3 center = textureGrad(samp, uv, dx, dy).rgb;
    vec3 axial = textureGrad(samp, mirrorUV(uv + vec2(px.x, 0.0)), dx, dy).rgb;
    axial += textureGrad(samp, mirrorUV(uv - vec2(px.x, 0.0)), dx, dy).rgb;
    axial += textureGrad(samp, mirrorUV(uv + vec2(0.0, px.y)), dx, dy).rgb;
    axial += textureGrad(samp, mirrorUV(uv - vec2(0.0, px.y)), dx, dy).rgb;
    return center * 0.60 + axial * 0.10;
}

vec2 kaleidoFold(vec2 uv, vec2 center, float aspect, float segments) {
    vec2 p = (uv - center) * vec2(aspect, 1.0);
    float radius = length(p);
    float wedge = TAU / max(segments, 3.0);
    float angle = abs(mod(atan(p.y, p.x) + 0.5 * wedge, wedge) - 0.5 * wedge);
    p = radius * vec2(cos(angle), sin(angle));
    return p / vec2(aspect, 1.0) + center;
}

vec2 largeFractalFold(vec2 uv, vec2 center, float aspect, float t,
                      float foldZoom, float seed, float bass, float mids) {
    vec2 p = uv;
    int foldSet = FOLD_VARIANT / 5;
    for (int i = 0; i < 4; ++i) {
        if (i >= 3 + (foldSet % 2)) break;
        float fi = float(i);
        float pulse = sin(t * (0.39 + fi * 0.075) + fi * 2.1 + seed);
        float scale = foldZoom + 0.050 * pulse + bass * 0.025;
        vec2 offset = vec2(0.47 - fi * 0.025,
                           0.45 - fi * 0.020 + 0.012 * sin(seed + fi));
        p = abs((p - center) * scale) - offset + center;
        float turn = 0.075 * sin(t * 0.31 + fi * 1.7 + seed);
        turn += mids * 0.025 * (fi + 1.0);
        p = rotateUV(p, turn, center, aspect);
    }
    return p;
}

float foldWave(int style, vec2 fp, float radius, float angle,
               float segments, float t, float ripple) {
    float diamond = max(abs(fp.x), abs(fp.y));
    float ring = sin(diamond * (12.0 + segments) - t * 1.7 + ripple);
    float radial = sin(radius * (23.0 + segments * 0.45) - t * 2.6 + ripple);
    float spiral = sin(angle * (2.0 + 0.25 * segments) +
                       radius * 18.0 - t * 2.2);
    float lattice = sin(fp.x * (18.0 + segments) + ripple) *
                    cos(fp.y * (16.0 + segments) + t);
    if (style == 1) return 0.62 * ring + 0.38 * radial;
    if (style == 2) return 0.68 * spiral + 0.32 * ring;
    if (style == 3) return 0.58 * lattice + 0.42 * spiral;
    if (style == 4) return 0.45 * ring + 0.35 * lattice + 0.20 * radial;
    return ring;
}

vec3 softLight(vec3 base, vec3 blend) {
    vec3 low = 2.0 * base * blend;
    vec3 high = 1.0 - 2.0 * (1.0 - base) * (1.0 - blend);
    return mix(low, high, step(vec3(0.5), base));
}

void main() {
    float bass = texture(spectrum0, 0.03).r;
    float mids = texture(spectrum0, 0.22).r;
    float highs = texture(spectrum0, 0.58).r;
    float air = texture(spectrum0, 0.80).r;

    int style = FOLD_VARIANT % 5;
    int foldSet = FOLD_VARIANT / 5;
    float variant = float(FOLD_VARIANT);
    float setValue = float(foldSet);
    float styleValue = float(style);
    float aspect = iResolution.x / max(iResolution.y, 1.0);
    vec2 ar = vec2(aspect, 1.0);
    vec2 mouseUV = iMouse.xy / max(iResolution, vec2(1.0));
    vec2 center = iMouse.z > 0.0 ? mouseUV : vec2(0.5);

    float motion = 0.38 + styleValue * 0.12 + setValue * 0.035;
    float t = time_f * motion;
    float segments = 5.0 + mod(variant * 3.0 + setValue, 10.0);
    segments += floor(mids * 3.0);
    float foldZoom = 1.075 + styleValue * 0.018 + setValue * 0.010;
    float distortion = 0.018 + styleValue * 0.0022 + setValue * 0.0012;

    vec2 local = (tc - center) * ar;
    float radius = length(local);
    float angle = atan(local.y, local.x);

    vec2 folded = kaleidoFold(tc, center, aspect, segments);
    folded = largeFractalFold(folded, center, aspect, t, foldZoom,
                              variant * 0.37, bass, mids);
    vec2 fp = (folded - center) * ar;

    vec2 rippleSource = vec2(sin(t * 0.43), cos(t * 0.37)) * 0.18;
    float rippleRadius = length(local - rippleSource);
    float ripple = sin(rippleRadius * (18.0 + bass * 9.0) - t * 4.0);
    ripple += 0.5 * sin(length(local + rippleSource * 0.7) *
                        (24.0 + highs * 8.0) - t * 5.1);
    ripple /= 1.5;

    float wave = foldWave(style, fp, radius, angle, segments, t, ripple);
    vec2 normalField = vec2(dFdx(wave), dFdy(wave));
    normalField /= max(length(normalField), 1e-4);
    vec2 radial = local / max(radius, 1e-4) / ar;
    vec2 tangent = vec2(-radial.y, radial.x / max(aspect, 1e-4));
    float envelope = smoothstep(1.20, 0.03, radius);
    float audioPush = 1.0 + bass * 0.30 + amp_smooth * 0.18;
    vec2 displacement = normalField * 0.56 + radial * wave * 0.29;
    displacement += tangent * ripple * (0.15 + 0.02 * styleValue);
    displacement *= distortion * envelope * audioPush;
    displacement.x /= max(aspect, 1.0);

    vec2 warpedUV = tc + displacement;
    vec2 chroma = normalField * (0.0008 + highs * 0.0017) * envelope;
    chroma.x /= max(aspect, 1.0);
    vec3 warped;
    warped.r = sampleLiveHQ(warpedUV + chroma).r;
    warped.g = sampleLiveHQ(warpedUV).g;
    warped.b = sampleLiveHQ(warpedUV - chroma).b;

    vec2 foldDetail = folded + normalField * distortion * (0.20 + air * 0.08);
    vec3 foldedLayer;
    foldedLayer.r = sampleLiveHQ(foldDetail + chroma * 1.5).r;
    foldedLayer.g = sampleLiveHQ(foldDetail).g;
    foldedLayer.b = sampleLiveHQ(foldDetail - chroma * 1.5).b;

    vec3 original = texture(samp, tc).rgb;
    float detail = 0.5 + 0.5 * wave;
    float aa = max(fwidth(wave), 0.001);
    float facet = smoothstep(0.42 - aa, 0.42 + aa, detail);
    vec3 tintA = blueTint(variant * 0.031 + t * 0.025);
    vec3 tintB = blueTint(0.22 + styleValue * 0.07 - t * 0.018);
    vec3 tint = mix(tintA, tintB, facet);
    vec3 fractalOverlap = mix(warped, foldedLayer, 0.54 + 0.05 * mids);
    vec3 treated = mix(fractalOverlap, fractalOverlap * tint,
                       0.25 + 0.10 * amp_smooth);
    float facetEdge = 1.0 - smoothstep(0.0, 0.10 + aa * 2.0,
                                       abs(detail - 0.42));
    treated += tint * facetEdge * (0.028 + 0.025 * amp_smooth);
    treated += (fractalOverlap - original) * (0.10 + 0.06 * mids);

    float centerFade = smoothstep(0.012, 0.12, radius);
    float effectMix = 0.48 + styleValue * 0.018 + setValue * 0.008;
    float blendAmount = effectMix * centerFade *
                        (0.94 + 0.06 * sin(t + radius * 5.0));
    vec3 layered = mix(treated, softLight(original, treated), 0.18);
    vec3 current = mix(original, layered, clamp(blendAmount, 0.0, 0.64));

    vec3 accum = current;
    float weightSum = 1.0;
    vec2 historyStretch = vec2(0.0);
    if (iMouse.w > 0.0) historyStretch = (mouseUV - vec2(0.5)) * 0.12;

    for (int i = 0; i < 8; ++i) {
        float generation = float(i + 1);
        float hBass = sampleSpectrumHistory(i, 0.03);
        float hMids = sampleSpectrumHistory(i, 0.22);
        float hHighs = sampleSpectrumHistory(i, 0.58);
        float hAir = sampleSpectrumHistory(i, 0.80);
        float zoom = pow(max(0.965 - hBass * 0.075 +
                             0.008 * sin(t), 0.20), generation);
        float rotation = (0.014 + hHighs * 0.075) * generation;
        rotation *= (style == 2 || style == 4) ? 1.0 : -1.0;
        vec2 historyUV = center + rotateUV(tc, rotation, center, aspect) - center;
        historyUV = (historyUV - center) * zoom + center;
        historyUV += historyStretch * generation;
        historyUV += displacement * generation * (0.14 + hMids * 0.10);
        vec3 cached = sampleCache(i, historyUV).rgb;
        vec3 historyTint = blueTint(variant * 0.02 + generation * 0.035 + hAir);
        cached = mix(cached, cached * historyTint, 0.18 + hMids * 0.08);
        cached += historyTint * facetEdge * (0.006 + hHighs * 0.008);
        float weight = pow(0.76, generation);
        accum += cached * weight;
        weightSum += weight;
    }

    accum /= weightSum;
    accum = mix(original, accum, 0.84);
    accum += vec3(0.003, 0.010, 0.032) * (1.0 + amp_smooth);
    accum *= vec3(0.84, 0.94, 1.10);
    accum = pow(clamp(accum, 0.0, 1.0), vec3(0.96));
    accum = mix(accum, vec3(1.0) - accum, smoothstep(0.88, 1.0, amp_peak));
    color = vec4(clamp(accum, 0.0, 1.0), 1.0);
}
