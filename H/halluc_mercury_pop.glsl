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

const float iAmplitude = 1.0;
const float iFrequency = 1.0;
const float iBrightness = 1.0;
const float iContrast = 1.20;
const float iSaturation = 1.40;
const float iHueShift = 0.0;
const float iZoom = 1.0;
const float iRotation = 0.0;
const float iMercuryGloss = 1.0;

vec3 palette(float t) {
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(1.0, 1.0, 1.0);
    vec3 d = vec3(0.0, 0.33, 0.67);
    return a + b * cos(6.28318 * (c * t + d + iHueShift));
}

vec2 wrapUV(vec2 v) { return 1.0 - abs(1.0 - 2.0 * fract(v * 0.5)); }

vec4 mxTexture(sampler2D tex, vec2 uv) {
    vec2 ts = vec2(textureSize(tex, 0));
    vec2 eps = 0.5 / ts;
    vec2 u = wrapUV(uv);
    return textureLod(tex, clamp(u, eps, 1.0 - eps), 0.0);
}

mat2 rot(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c);
}

vec3 mercuryFractal(vec2 uv, vec2 center, float t) {
    vec2 p = uv - center;
    p.x *= iResolution.x / iResolution.y;
    p /= 0.5 + iZoom * 2.0;

    vec3 accTex = vec3(0.0);
    float accGlare = 0.0;
    float ringD = 100.0;

    float iter = 5.0;
    float scale = 1.55 + iAmplitude * 0.45;

    for (float i = 0.0; i < iter; i++) {
        // sphere inversion: makes everything bulge / blob
        float r2 = dot(p, p);
        if (r2 > 0.0001)
            p /= max(r2, 0.35);

        // box fold
        p = clamp(p, -1.0, 1.0) * 2.0 - p;

        p *= rot(t * 0.15 + iRotation + i * 0.6);
        p *= scale;
        p -= vec2(sin(t * 0.5 + i), cos(t * 0.4 + i)) * 0.08;

        vec2 texUV = p * 0.5 + 0.5;
        accTex += mxTexture(samp, texUV).rgb / (i + 1.0);

        float dist = length(p);
        ringD = min(ringD, abs(dist - 0.6));
        accGlare += exp(-12.0 * abs(dist - 0.4));
    }
    accTex /= 1.6;

    // chrome-like reflective tint based on direction
    vec2 dir = normalize(p + 1e-6);
    float fres = pow(1.0 - abs(dir.y), 2.0);
    vec3 chrome = mix(vec3(0.3, 0.4, 0.55), vec3(1.0, 0.95, 0.9), fres);
    chrome *= 0.7 + 0.6 * iMercuryGloss;

    vec3 pal = palette(ringD * 1.2 + t * 0.15);
    vec3 col = mix(accTex, chrome, 0.55);
    col = mix(col, pal, 0.30 * iSaturation);
    col += pal * accGlare * 0.5 * iContrast;
    // hard specular glints on tight ring
    col += vec3(1.0, 0.95, 0.85) * exp(-50.0 * ringD) * 0.6;
    return col;
}

void main() {
    vec2 uv = tc;
    vec2 center = vec2(0.5);
    if (iMouse.z > 0.0)
        center = iMouse.xy / iResolution;
    float bass = texture(spectrum, 0.03).r + amp_low * 0.5;
    float midF = texture(spectrum, 0.22).r + amp_mid * 0.5;
    float treble = texture(spectrum, 0.58).r + amp_high * 0.5;
    float beat = max(amp_peak, bass);
    float t = time_f * (0.08 + iFrequency * 0.20) * (1.0 + 0.6 * beat);

    vec3 col = mercuryFractal(uv, center, t);

    float gray = dot(col, vec3(0.299, 0.587, 0.114));
    col = mix(vec3(gray), col, iSaturation);
    col = (col - 0.5) * iContrast + 0.5;
    col += vec3(0.6, 0.4, 1.0) * treble * 0.18;
    col *= iBrightness * (1.0 + 0.5 * bass);

    vec2 vUV = uv * (1.0 - uv.yx);
    float vig = pow(vUV.x * vUV.y * 15.0, 0.18);
    col *= vig;

    color = vec4(col, 1.0);
}
