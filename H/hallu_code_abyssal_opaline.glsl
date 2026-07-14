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

const float TAU = 6.28318530718;
const float iBrightness = 1.02;
const float iContrast = 1.16;
const float iSaturation = 1.36;

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
    return textureLod(samp, clamp(wrapUV(uv), edge, 1.0 - edge), 0.0).rgb;
}

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), u.x),
               mix(hash21(i + vec2(0.0, 1.0)), hash21(i + 1.0), u.x), u.y);
}

float fbm(vec2 p) {
    float sum = 0.0;
    float amplitude = 0.52;
    mat2 octave = mat2(1.74, 1.08, -1.08, 1.74);
    for (int i = 0; i < 7; ++i) {
        sum += amplitude * noise(p);
        p = octave * p + vec2(0.13, -0.09);
        amplitude *= 0.49;
    }
    return sum;
}

vec2 curlField(vec2 p, float t) {
    float e = 0.025;
    float n1 = fbm(p + vec2(0.0, e) + t * 0.035);
    float n2 = fbm(p - vec2(0.0, e) + t * 0.035);
    float n3 = fbm(p + vec2(e, 0.0) - t * 0.029);
    float n4 = fbm(p - vec2(e, 0.0) - t * 0.029);
    return vec2(n1 - n2, n4 - n3) / (2.0 * e);
}

vec3 opalPalette(float t) {
    vec3 base = vec3(0.50);
    vec3 range = vec3(0.50);
    vec3 rate = vec3(1.0, 0.78, 1.24);
    vec3 phase = vec3(0.01, 0.27, 0.58);
    return base + range * cos(TAU * (rate * t + phase));
}

// Integer angular harmonics guarantee continuity across the atan branch cut.
vec3 angularOpal(float angle, float phase) {
    vec3 harmonic = vec3(1.0, 2.0, 3.0);
    vec3 offset = vec3(0.02, 0.31, 0.61);
    return 0.5 + 0.5 * cos(harmonic * angle + TAU * (phase + offset));
}

float gyroid(vec3 p) {
    return dot(sin(p), cos(p.yzx));
}

vec3 abyssalOpal(vec2 uv, vec2 center, float t, vec3 audio) {
    float aspect = iResolution.x / max(iResolution.y, 1.0);
    vec2 p = (uv - center) * vec2(aspect, 1.0);
    float originalRadius = length(p);
    float angle = atan(p.y, p.x);

    // Spiral the image into a deep lens, then advect it through a curl field.
    float lens = 1.0 / (0.24 + originalRadius);
    float twist = 1.05 * exp(-1.7 * originalRadius) + audio.y * 0.20;
    p *= rot(t * 0.08 + twist * sin(t * 0.31 + originalRadius * 7.0));
    vec2 curl = curlField(p * 1.85 + vec2(cos(t * 0.13), sin(t * 0.11)), t);
    p += curl * (0.075 + audio.x * 0.035);

    vec2 q = vec2(fbm(p * 2.4 + curl + vec2(t * 0.12, 0.0)),
                  fbm(p.yx * 2.1 - curl + vec2(4.7, -t * 0.10)));
    vec2 r = vec2(fbm(p * 3.0 + q * 3.8 + vec2(-t * 0.08, 8.1)),
                  fbm(p.yx * 3.2 - q * 3.4 + vec2(2.6, t * 0.09)));
    vec2 flow = p + (r - 0.5) * (0.30 + audio.x * 0.12);

    vec3 texAccum = vec3(0.0);
    float weightSum = 0.0;
    float filament = 0.0;
    float caustic = 0.0;
    float shell = 10.0;
    vec2 z = flow;

    for (int i = 0; i < 6; ++i) {
        float fi = float(i);
        float radial = length(z);
        float localAngle = atan(z.y, z.x);
        float wave = sin(radial * (15.0 + fi * 2.1) - localAngle * (3.0 + fi) - t * 0.9);
        z += 0.045 * vec2(cos(localAngle + wave), sin(localAngle - wave));
        z = abs(z * rot(0.47 + fi * 0.62 + t * 0.018)) - vec2(0.18, 0.135);
        z *= 1.29 + 0.035 * fi;

        float g = abs(gyroid(vec3(z * (4.0 + fi * 0.25), t * 0.42 + fi)));
        filament += exp(-7.5 * g) / (1.0 + fi * 0.48);
        caustic += pow(max(0.0, 1.0 - g), 6.0) / (1.0 + fi * 0.65);
        shell = min(shell, abs(radial - 0.19 - fi * 0.065));

        float weight = 1.0 / (1.0 + fi * 0.55);
        vec2 texUV = z * (0.26 + fi * 0.018) + 0.5;
        texUV += (q - 0.5) * 0.10;
        texAccum += sampleMirror(texUV) * weight;
        weightSum += weight;
    }
    texAccum /= weightSum;

    float depthBands = 0.5 + 0.5 * sin(lens * 4.8 - t * 1.15 + q.x * 5.0);
    float pearl = 0.5 + 0.5 * sin(filament * 2.8 + r.y * 8.0 - t * 0.25);
    float portal = exp(-4.0 * originalRadius) *
                   (0.58 + 0.42 * cos(angle * (5.0 + floor(audio.y * 4.0)) + t));
    float shellGlow = exp(-34.0 * shell);

    vec3 opal = opalPalette(pearl * 0.46 + depthBands * 0.18 + t * 0.022);
    vec3 abyss = vec3(0.015, 0.025, 0.07) +
                 opalPalette(q.x * 0.18 + 0.67) * 0.13;
    vec3 col = mix(abyss, texAccum * (0.55 + opal * 0.55), 0.62 + 0.20 * r.x);
    col = mix(col, opal, clamp(filament * 0.16, 0.0, 0.48));
    col += opal * caustic * (0.12 + audio.z * 0.085);
    col += angularOpal(angle, t * 0.045) * shellGlow * 0.32;
    col += vec3(0.50, 0.72, 1.0) * portal * depthBands * 0.34;

    // Fine diffraction strands shimmer on high frequencies without strobing.
    float diffraction = pow(0.5 + 0.5 * cos(angle * 18.0 + lens * 2.0 - t), 12.0);
    col += angularOpal(angle, pearl) * diffraction *
           exp(-2.2 * originalRadius) * (0.04 + audio.z * 0.14);
    return col;
}

void main() {
    vec2 uv = tc;
    vec2 center = vec2(0.5);
    if (iMouse.z > 0.0) {
        center = iMouse.xy / iResolution;
    }

    float bass = clamp(texture(spectrum, 0.025).r + amp_low * 0.65, 0.0, 2.0);
    float mids = clamp(texture(spectrum, 0.24).r + amp_mid * 0.62, 0.0, 2.0);
    float highs = clamp(texture(spectrum, 0.67).r + amp_high * 0.68, 0.0, 2.0);
    float beat = max(amp_peak, bass);
    float t = time_f * 0.18 * (1.0 + beat * 0.40);

    vec3 col = abyssalOpal(uv, center, t, vec3(bass, mids, highs));

    float luma = dot(col, vec3(0.299, 0.587, 0.114));
    col = mix(vec3(luma), col, iSaturation);
    col = (col - 0.5) * iContrast + 0.5;
    col *= iBrightness * (1.0 + bass * 0.20 + amp_smooth * 0.14);
    col = col / (0.88 + 0.30 * col); // filmic highlight rolloff

    vec2 vignetteUV = uv * (1.0 - uv.yx);
    float vignette = pow(max(vignetteUV.x * vignetteUV.y * 15.5, 0.0), 0.18);
    color = vec4(max(col * vignette, 0.0), 1.0);
}
