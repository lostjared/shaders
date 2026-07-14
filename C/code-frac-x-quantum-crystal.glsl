#version 330 core
// code-frac-x-quantum-crystal: 4K+ derivative-filtered remix of the Acid Cam frac shader family.
// Domain engine: triangular crystal lattice. Detail engine: smooth Julia escape field.
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

const float PI = 3.14159265358979323846;
const float TAU = 6.28318530717958647692;
const float SEGMENTS = 12.0;
const float FOLD_GAIN = 1.315;
const float SPIN_RATE = 0.170;
const float WARP_STRENGTH = 0.700;
const float TEXTURE_MIX = 0.755;
const float EXPOSURE = 1.110;
const float HUE_SHIFT = 0.818;

mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

float saturate(float x) { return clamp(x, 0.0, 1.0); }
vec2 saturate(vec2 x) { return clamp(x, 0.0, 1.0); }
vec3 saturate(vec3 x) { return clamp(x, 0.0, 1.0); }

vec2 hash22(vec2 p) {
    vec3 q = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    q += dot(q, q.yzx + 33.33);
    return fract((q.xx + q.yz) * q.zy);
}

float valueNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    float a = hash22(i).x;
    float b = hash22(i + vec2(1.0, 0.0)).x;
    float c = hash22(i + vec2(0.0, 1.0)).x;
    float d = hash22(i + vec2(1.0, 1.0)).x;
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm6(vec2 p) {
    float sum = 0.0;
    float weight = 0.5;
    mat2 octave = rot(0.53) * 2.03;
    for (int i = 0; i < 6; ++i) {
        sum += weight * valueNoise(p);
        p = octave * p + vec2(17.13, 9.71);
        weight *= 0.5;
    }
    return sum / 0.984375;
}

vec2 flowNoise(vec2 p) {
    return vec2(fbm6(p + vec2(7.1, 1.7)),
                fbm6(rot(1.57) * p + vec2(3.8, 11.3))) * 2.0 - 1.0;
}

vec2 complexMul(vec2 a, vec2 b) {
    return vec2(a.x * b.x - a.y * b.y, a.x * b.y + a.y * b.x);
}

vec2 complexDiv(vec2 a, vec2 b) {
    float d = max(dot(b, b), 1e-4);
    return vec2(a.x * b.x + a.y * b.y, a.y * b.x - a.x * b.y) / d;
}

vec2 kaleido(vec2 p, float segments) {
    float radius = length(p);
    float slice = TAU / max(segments, 2.0);
    float angle = atan(p.y, p.x);
    angle = abs(mod(angle + 0.5 * slice, slice) - 0.5 * slice);
    return radius * vec2(cos(angle), sin(angle));
}

vec2 mirrorWrap(vec2 uv) {
    return 1.0 - abs(mod(uv, 2.0) - 1.0);
}

vec2 boundedFold(vec2 p) {
    p = abs(p);
    if (p.y > p.x) p = p.yx;
    return clamp(p, vec2(-3.0), vec2(3.0));
}

float aaLine(float distanceToLine, float halfWidth) {
    float aa = max(fwidth(distanceToLine), 1.0 / max(min(iResolution.x, iResolution.y), 1.0));
    return 1.0 - smoothstep(halfWidth - aa, halfWidth + aa, abs(distanceToLine));
}

float aaPulse(float phase, float width) {
    float wave = abs(fract(phase) - 0.5);
    float aa = max(fwidth(phase), 1.0 / max(min(iResolution.x, iResolution.y), 1.0));
    return 1.0 - smoothstep(width - aa, width + aa, wave);
}

vec3 cosinePalette(float x) {
    vec3 base = vec3(0.52, 0.48, 0.50);
    vec3 amplitude = vec3(0.48, 0.46, 0.50);
    vec3 frequency = vec3(1.00, 1.04, 0.96);
    vec3 phase = vec3(HUE_SHIFT, HUE_SHIFT + 0.21, HUE_SHIFT + 0.43);
    return saturate(base + amplitude * cos(TAU * (frequency * x + phase)));
}

// A bounded twelve-generation inversion IFS. Besides its final coordinate it
// carries three orbit traps, so later lighting is tied to real fractal history.
vec4 deepOrbit(vec2 seed, float t, vec4 audio) {
    vec2 z = seed;
    float lineTrap = 10.0;
    float pointTrap = 10.0;
    float energy = 0.0;
    for (int i = 0; i < 12; ++i) {
        float fi = float(i);
        z = rot(0.37 + SPIN_RATE * 0.17 + 0.025 * sin(t * 0.21 + fi)) * z;
        z = abs(z) - vec2(0.42 + 0.035 * sin(fi * 1.7 + t * 0.13),
                          0.31 + 0.040 * cos(fi * 1.3 - t * 0.16));
        float inverseRadius = clamp(dot(z, z), 0.16, 1.45);
        z = z * (FOLD_GAIN / inverseRadius) - vec2(0.36, 0.24);
        z += 0.025 * audio.xy * vec2(sin(fi + t), cos(fi - t));
        lineTrap = min(lineTrap, min(abs(z.x), abs(z.y)));
        pointTrap = min(pointTrap, length(z - vec2(0.22, -0.18)));
        energy += exp(-2.8 * abs(dot(z, normalize(vec2(0.8, 0.6))))) / 12.0;
    }
    return vec4(lineTrap, pointTrap, energy, atan(z.y, z.x) / TAU + 0.5);
}

// Seven-tap explicit-gradient sampling: texture detail remains stable across
// nonlinear folds, while all chromatic offsets are specified in source pixels.
vec3 sampleTextureHQ(vec2 uv, vec2 direction, float splitPixels) {
    vec2 texSize = max(vec2(textureSize(samp, 0)), vec2(1.0));
    vec2 texel = 1.0 / texSize;
    uv = mirrorWrap(uv);
    vec2 gx = dFdx(uv);
    vec2 gy = dFdy(uv);
    vec2 axis = normalize(direction + vec2(1e-5));
    vec2 tangent = vec2(-axis.y, axis.x);
    vec2 tapA = axis * texel * 0.72;
    vec2 tapB = tangent * texel * 0.72;
    vec3 center = textureGrad(samp, uv, gx, gy).rgb;
    vec3 filtered = center * 0.40;
    filtered += textureGrad(samp, mirrorWrap(uv + tapA), gx, gy).rgb * 0.15;
    filtered += textureGrad(samp, mirrorWrap(uv - tapA), gx, gy).rgb * 0.15;
    filtered += textureGrad(samp, mirrorWrap(uv + tapB), gx, gy).rgb * 0.15;
    filtered += textureGrad(samp, mirrorWrap(uv - tapB), gx, gy).rgb * 0.15;
    vec2 split = axis * texel * splitPixels;
    float red = textureGrad(samp, mirrorWrap(uv + split), gx, gy).r;
    float blue = textureGrad(samp, mirrorWrap(uv - split), gx, gy).b;
    return mix(filtered, vec3(red, filtered.g, blue), 0.68);
}

// Ten-generation triangular crystal lattice with Weyl-chamber swaps and
// nested mirror cells, extending the diamond and octagonal frac lineages.
vec2 remixDomain(vec2 p, float t, vec4 audio) {
    const mat2 triangular = mat2(1.0, 0.577350269, 0.0, 1.154700538);
    p = triangular * rot(t * SPIN_RATE * 0.13) * p;
    p = kaleido(p, SEGMENTS + floor(audio.y * 3.0));
    for (int i = 0; i < 10; ++i) {
        float fi = float(i);
        p = abs(fract(p * (1.31 + fi * 0.012) + vec2(0.5, 0.37)) - 0.5);
        if (p.x + p.y > 0.54) p = vec2(0.54) - p.yx;
        p = rot(0.36 + 0.035 * sin(t * 0.2 + fi * 1.31)) * p;
        p *= 1.86 + audio.z * 0.08;
    }
    return p - vec2(0.22, 0.15);
}

// Forty-iteration Julia escape field with smooth iteration bands and dual
// orbit traps. The parameter drifts slowly and responds to bass/mouse centering.
vec3 remixDetail(vec2 p, vec2 original, float t, vec4 audio, vec4 orbit) {
    vec2 z = p * (1.28 + audio.x * 0.12);
    vec2 c = vec2(-0.745 + 0.055 * sin(t * 0.071 + HUE_SHIFT * TAU),
                   0.113 + 0.060 * cos(t * 0.093 - HUE_SHIFT * TAU));
    float escapedAt = 40.0;
    float circleTrap = 10.0;
    float crossTrap = 10.0;
    for (int i = 0; i < 40; ++i) {
        circleTrap = min(circleTrap, abs(length(z) - 0.52));
        crossTrap = min(crossTrap, min(abs(z.x), abs(z.y)));
        z = complexMul(z, z) + c;
        if (dot(z, z) > 256.0) {
            escapedAt = float(i);
            break;
        }
    }
    float smoothIteration = escapedAt;
    if (escapedAt < 40.0) {
        smoothIteration += 1.0 - log2(max(log2(max(dot(z, z), 2.0)), 1e-4));
    }
    float bands = aaPulse(smoothIteration * 0.082 + orbit.w * 0.7 - t * 0.025, 0.16);
    float orbitGlow = exp(-18.0 * circleTrap) + 0.55 * exp(-24.0 * crossTrap);
    float interior = smoothstep(38.0, 40.0, smoothIteration);
    return vec3(saturate(bands), saturate(orbitGlow), saturate(interior + orbit.z * 0.2));
}

vec3 screenBlend(vec3 a, vec3 b) {
    return 1.0 - (1.0 - a) * (1.0 - b);
}

vec3 filmicToneMap(vec3 x) {
    x = max(x, vec3(0.0));
    return saturate((x * (2.51 * x + 0.03)) /
                    (x * (2.43 * x + 0.59) + 0.14));
}

void main() {
    vec2 resolution = max(iResolution, vec2(1.0));
    float aspect = resolution.x / resolution.y;
    vec2 aspectScale = vec2(aspect, 1.0);
    vec4 source = texture(samp, tc);
    vec2 center = (iMouse.z > 0.5) ? saturate(iMouse.xy / resolution) : vec2(0.5);

    float bass = saturate(amp_low);
    float mids = saturate(amp_mid);
    float highs = saturate(amp_high);
    float peak = saturate(max(amp_peak, iamp));
    vec4 audio = vec4(bass, mids, highs, peak);
    float t = time_f;

    vec2 original = (tc - center) * aspectScale;
    float breathingZoom = 1.0 + 0.07 * sin(t * 0.19) + bass * 0.10;
    original = rot(t * SPIN_RATE * 0.11) * original * breathingZoom;

    vec2 domain = remixDomain(original, t, audio);
    vec4 orbit = deepOrbit(domain, t, audio);
    vec3 detail = remixDetail(domain, original, t, audio, orbit);

    float radius = length(domain);
    float angle = atan(domain.y, domain.x);
    float logPhase = log(radius + 0.025) * (1.7 + WARP_STRENGTH) - t * (0.075 + bass * 0.045);
    vec2 textureDomain = rot(angle * 0.08 + orbit.w * 0.35) * domain;
    textureDomain += 0.075 * vec2(sin(logPhase * 2.3 + t * 0.11),
                                  cos(logPhase * 1.9 - t * 0.09));
    vec2 warpedUV = center + textureDomain / aspectScale * (0.34 + 0.04 * sin(logPhase));
    warpedUV = mirrorWrap(warpedUV);

    vec2 sampleDirection = normalize(vec2(cos(angle + orbit.w * TAU),
                                          sin(angle + orbit.w * TAU)) + vec2(1e-5));
    float splitPixels = 0.8 + highs * 5.5 + detail.y * 1.4;
    vec3 warpedTexture = sampleTextureHQ(warpedUV, sampleDirection, splitPixels);

    float palettePhase = orbit.w + detail.x * 0.19 + detail.y * 0.13
                       + detail.z * 0.11 + logPhase * 0.075 + t * 0.018;
    vec3 palette = cosinePalette(palettePhase);
    vec3 companion = cosinePalette(palettePhase + 0.31 + orbit.z * 0.12);

    float geometry = saturate(0.28 + detail.x * 0.48 + detail.y * 0.30);
    float luminosity = 0.68 + orbit.z * 0.38 + detail.z * 0.34;
    vec3 coloredTexture = warpedTexture * mix(vec3(1.0), palette * 1.34, 0.54 + mids * 0.14);
    vec3 luminousLayer = screenBlend(coloredTexture, companion * geometry * 0.82);
    vec3 fractalColor = mix(coloredTexture, luminousLayer, 0.58 + peak * 0.18);
    fractalColor *= luminosity;
    fractalColor += palette * (detail.x * 0.15 + detail.y * 0.10 + orbit.z * 0.08);

    float sourceLuma = dot(source.rgb, vec3(0.2126, 0.7152, 0.0722));
    fractalColor = mix(fractalColor, fractalColor * (0.72 + sourceLuma * 0.56), 0.34);
    float blendAmount = saturate(TEXTURE_MIX + geometry * 0.10 + peak * 0.06);
    vec3 outputColor = mix(source.rgb, fractalColor, blendAmount);

    vec2 vignettePoint = (tc - center) * aspectScale;
    float vignette = 1.0 - smoothstep(0.58, 1.42, length(vignettePoint));
    outputColor *= 0.82 + vignette * 0.18;
    outputColor *= EXPOSURE * (1.0 + peak * 0.24);
    outputColor = mix(outputColor / (1.0 + outputColor), filmicToneMap(outputColor), 0.72);

    color = vec4(saturate(outputColor), source.a);
}
