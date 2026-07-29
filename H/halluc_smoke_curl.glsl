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

const float iAmplitude  = 1.0;
const float iFrequency  = 0.7;
const float iBrightness = 0.95;
const float iContrast   = 1.10;
const float iSaturation = 0.85;
const float iHueShift   = 0.30;
const float iZoom       = 1.0;
const float iRotation   = 0.0;
const float iSmokeDensity = 1.10;

vec3 palette(float t) {
    vec3 a = vec3(0.45, 0.45, 0.50);
    vec3 b = vec3(0.30, 0.30, 0.35);
    vec3 c = vec3(1.0, 1.0, 1.0);
    vec3 d = vec3(0.55, 0.60, 0.70);
    return a + b * cos(6.28318 * (c * t + d + iHueShift));
}

vec2 wrapUV(vec2 v) { return 1.0 - abs(1.0 - 2.0 * fract(v * 0.5)); }

vec4 mxTexture(sampler2D tex, vec2 uv) {
    vec2 ts = vec2(textureSize(tex, 0));
    vec2 eps = 0.5 / ts;
    vec2 u = wrapUV(uv);
    return textureLod(tex, clamp(u, eps, 1.0 - eps), 0.0);
}

mat2 rot(float a) { float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

float hash21(vec2 p) {
    p = fract(p * vec2(73.71, 19.13));
    p += dot(p, p + 51.7);
    return fract(p.x * p.y);
}
float vnoise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    float a = hash21(i);
    float b = hash21(i + vec2(1.0, 0.0));
    float c = hash21(i + vec2(0.0, 1.0));
    float d = hash21(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}
float fbm(vec2 p) {
    float v = 0.0, a = 0.5;
    for (int i = 0; i < 6; ++i) { v += a * vnoise(p); p = rot(0.5) * p * 2.07; a *= 0.5; }
    return v;
}

// curl-like 2D field via finite differences of fbm
vec2 curl(vec2 p, float t) {
    float e = 0.05;
    float a = fbm(p + vec2(0.0, e) + t);
    float b = fbm(p - vec2(0.0, e) + t);
    float c = fbm(p + vec2(e, 0.0) - t);
    float d = fbm(p - vec2(e, 0.0) - t);
    return vec2(a - b, d - c) / (2.0 * e);
}

vec3 smokeStack(vec2 uv, vec2 center, float t) {
    vec2 p = uv - center;
    p.x *= iResolution.x / iResolution.y;
    p /= 0.5 + iZoom * 2.0;

    // advect: smoke rises and curls
    vec2 c = curl(p * 1.2, t * 0.4);
    p += c * 0.25 * iAmplitude;
    p.y -= t * 0.20;

    float density = 0.0;
    vec3 accTex = vec3(0.0);
    float iter = 4.0;
    float scale = 1.40 + iAmplitude * 0.3;

    for (float i = 0.0; i < iter; i++) {
        p = abs(p);
        p -= 0.18;
        p *= rot(t * 0.10 + iRotation + i * 0.7);
        p *= scale;

        float n = fbm(p * 1.3 + vec2(0.0, -t * 0.5) + i);
        density += n / (i + 1.0);

        vec2 texUV = p * 0.5 + 0.5;
        texUV += c * 0.04;
        accTex += mxTexture(samp, texUV).rgb * (0.55 / (i + 1.0));
    }
    density = clamp(density * iSmokeDensity, 0.0, 1.5);

    vec3 pal = palette(density * 0.5 + t * 0.07);
    // smoke is mostly desaturated
    vec3 smoke = mix(vec3(dot(pal, vec3(0.33))), pal, 0.35);

    // rising soot mask
    float mask = smoothstep(0.10, 0.95, density);
    vec3 col = mix(accTex, smoke * (0.4 + 0.6 * density), mask);
    col += vec3(0.04, 0.05, 0.08) * pow(density, 3.0); // dark soot
    return col;
}

void main() {
    vec2 uv = tc;
    vec2 center = vec2(0.5);
    if (iMouse.z > 0.0) center = iMouse.xy / iResolution;
    float bass   = texture(spectrum, 0.03).r + amp_low  * 0.5;
    float midF   = texture(spectrum, 0.22).r + amp_mid  * 0.5;
    float treble = texture(spectrum, 0.58).r + amp_high * 0.5;
    float beat   = max(amp_peak, bass);
    float t = time_f * (0.08 + iFrequency * 0.18) * (1.0 + 0.6 * beat);

    vec3 col = smokeStack(uv, center, t);

    float gray = dot(col, vec3(0.299, 0.587, 0.114));
    col = mix(vec3(gray), col, iSaturation);
    col = (col - 0.5) * iContrast + 0.5;
    col += vec3(0.6, 0.4, 1.0) * treble * 0.18;
    col *= iBrightness * (1.0 + 0.5 * bass);

    vec2 vUV = uv * (1.0 - uv.yx);
    float vig = pow(vUV.x * vUV.y * 15.0, 0.22);
    col *= vig;

    color = vec4(col, 1.0);
}
