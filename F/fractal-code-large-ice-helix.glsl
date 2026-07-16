#version 330 core
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

// Transparent large-form fractal distortion: ice helix.
const float PI = 3.14159265358979323846;
const int STYLE = 2;
const float SEGMENTS = 6.000;
const float FOLD_ZOOM = 1.210;
const float MOTION = 0.560;
const float DISTORTION = 0.023;
const float EFFECT_MIX = 0.520;
const vec3 TINT_A = vec3(0.860, 1.060, 1.160);
const vec3 TINT_B = vec3(1.080, 0.960, 0.880);

vec2 rotateUV(vec2 uv, float angle, vec2 center, float aspect) {
    float s = sin(angle);
    float c = cos(angle);
    vec2 p = (uv - center) * vec2(aspect, 1.0);
    p = mat2(c, -s, s, c) * p;
    return p / vec2(aspect, 1.0) + center;
}

vec2 mirrorUV(vec2 uv) {
    vec2 tile = mod(uv, 2.0);
    return 1.0 - abs(1.0 - tile);
}

vec2 kaleidoFold(vec2 uv, vec2 center, float aspect, float segments) {
    vec2 p = (uv - center) * vec2(aspect, 1.0);
    float radius = length(p);
    float wedge = 2.0 * PI / max(segments, 3.0);
    float angle = abs(mod(atan(p.y, p.x) + 0.5 * wedge, wedge) - 0.5 * wedge);
    p = radius * vec2(cos(angle), sin(angle));
    return p / vec2(aspect, 1.0) + center;
}

vec2 largeFractalFold(vec2 uv, vec2 center, float aspect, float t) {
    vec2 p = uv;
    for (int i = 0; i < 3; ++i) {
        float fi = float(i);
        float scale = FOLD_ZOOM + 0.055 * sin(t * (0.43 + fi * 0.08) + fi * 2.1);
        p = abs((p - center) * scale) - vec2(0.47 - fi * 0.025) + center;
        p = rotateUV(p, 0.08 * sin(t * 0.31 + fi * 1.7), center, aspect);
    }
    return p;
}

vec3 sampleHQ(vec2 uv) {
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

void main(void) {
    float aspect = iResolution.x / max(iResolution.y, 1.0);
    float bass = clamp(amp_low, 0.0, 1.0);
    float mids = clamp(amp_mid, 0.0, 1.0);
    float highs = clamp(amp_high, 0.0, 1.0);
    float energy = clamp(amp_smooth, 0.0, 1.0);
    float t = time_f * MOTION;
    vec2 center = iMouse.z > 0.5 ? iMouse.xy / max(iResolution, vec2(1.0)) : vec2(0.5);
    vec2 ar = vec2(aspect, 1.0);
    vec2 local = (tc - center) * ar;
    float radius = length(local);
    float angle = atan(local.y, local.x);

    vec2 folded = kaleidoFold(tc, center, aspect, SEGMENTS + floor(mids * 3.0));
    folded = largeFractalFold(folded, center, aspect, t);
    vec2 fp = (folded - center) * ar;
    float diamond = max(abs(fp.x), abs(fp.y));
    float ring = sin(diamond * (12.0 + SEGMENTS) - t * 1.7);
    float spiral = sin(angle * (2.0 + 0.25 * SEGMENTS) + radius * 18.0 - t * 2.2);
    float lattice = sin(fp.x * (18.0 + SEGMENTS)) * cos(fp.y * (16.0 + SEGMENTS) + t);
    float wave = ring;

    if (STYLE == 1) {
        wave = 0.62 * ring + 0.38 * sin(radius * 28.0 - t * 2.6);
    } else if (STYLE == 2) {
        wave = 0.68 * spiral + 0.32 * ring;
    } else if (STYLE == 3) {
        wave = 0.58 * lattice + 0.42 * spiral;
    } else if (STYLE == 4) {
        wave = 0.45 * ring + 0.35 * lattice + 0.20 * spiral;
    }

    vec2 normalField = vec2(dFdx(wave), dFdy(wave));
    float normalLength = max(length(normalField), 1e-4);
    normalField /= normalLength;
    vec2 radial = local / max(radius, 1e-4) / ar;
    vec2 tangent = vec2(-radial.y, radial.x / max(aspect, 1e-4));
    float envelope = smoothstep(1.15, 0.05, radius);
    float audioPush = 1.0 + bass * 0.28 + energy * 0.16;
    vec2 displacement = (normalField * 0.58 + radial * wave * 0.30 + tangent * spiral * 0.12);
    displacement *= DISTORTION * envelope * audioPush;
    displacement.x /= max(aspect, 1.0);

    vec2 warpedUV = tc + displacement;
    vec2 chroma = normalField * (0.0007 + highs * 0.0013) * envelope;
    chroma.x /= max(aspect, 1.0);
    vec3 warped;
    warped.r = sampleHQ(warpedUV + chroma).r;
    warped.g = sampleHQ(warpedUV).g;
    warped.b = sampleHQ(warpedUV - chroma).b;

    // A direct folded copy makes the large fractal readable as a texture overlap.
    vec2 foldDetail = folded + normalField * DISTORTION * 0.22;
    vec3 foldedLayer;
    foldedLayer.r = sampleHQ(foldDetail + chroma * 1.5).r;
    foldedLayer.g = sampleHQ(foldDetail).g;
    foldedLayer.b = sampleHQ(foldDetail - chroma * 1.5).b;

    vec3 original = texture(samp, tc).rgb;
    float detail = 0.5 + 0.5 * wave;
    float aa = max(fwidth(wave), 0.001);
    float facet = smoothstep(0.42 - aa, 0.42 + aa, detail);
    vec3 tint = mix(TINT_A, TINT_B, facet);
    vec3 fractalOverlap = mix(warped, foldedLayer, 0.58 + 0.08 * mids);
    vec3 treated = mix(fractalOverlap, fractalOverlap * tint, 0.30 + 0.12 * energy);
    float facetEdge = 1.0 - smoothstep(0.0, 0.10 + aa * 2.0, abs(detail - 0.42));
    treated += tint * facetEdge * (0.035 + 0.025 * energy);
    treated += (fractalOverlap - original) * (0.14 + 0.07 * mids);

    float centerFade = smoothstep(0.015, 0.13, radius);
    float blendAmount = EFFECT_MIX * centerFade * (0.92 + 0.08 * sin(t + radius * 5.0));
    blendAmount *= 1.0 + 0.10 * clamp(amp_peak, 0.0, 1.0);
    // Soft-light-style compositing keeps source detail while visibly layering the fold.
    vec3 lowOverlay = 2.0 * original * treated;
    vec3 highOverlay = 1.0 - 2.0 * (1.0 - original) * (1.0 - treated);
    vec3 overlay = mix(lowOverlay, highOverlay, step(vec3(0.5), original));
    vec3 layered = mix(treated, overlay, 0.24);
    vec3 finalRGB = mix(original, layered, clamp(blendAmount, 0.0, 0.68));
    color = vec4(clamp(finalRGB, 0.0, 1.0), texture(samp, tc).a);
}
