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

// Controls
const float iAmplitude = 1.0;
const float iFrequency = 1.0;
const float iBrightness = 1.0;
const float iContrast = 1.15;
const float iSaturation = 1.25;
const float iHueShift = 0.05;
const float iZoom = 1.0;
const float iRotation = 0.0;
const float iViscosity = 0.65; // how "liquid" the fold is

// --- Helpers ---
vec3 palette(float t) {
    vec3 a = vec3(0.5, 0.45, 0.55);
    vec3 b = vec3(0.45, 0.55, 0.5);
    vec3 c = vec3(1.0, 1.0, 1.0);
    vec3 d = vec3(0.10, 0.40, 0.70);
    return a + b * cos(6.28318 * (c * t + d + iHueShift));
}

vec2 wrapUV(vec2 v) {
    return 1.0 - abs(1.0 - 2.0 * fract(v * 0.5));
}

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

// 2D value noise for liquid distortion
float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
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
    for (int i = 0; i < 5; ++i) {
        v += a * vnoise(p);
        p *= 2.03;
        a *= 0.5;
    }
    return v;
}

vec3 liquidFractal(vec2 uv, vec2 center, float t) {
    vec2 p = uv - center;
    p.x *= iResolution.x / iResolution.y;
    float zoomFactor = 0.5 + (iZoom * 2.0);
    p /= zoomFactor;

    // Liquid pre-displacement (the "pour")
    vec2 flow = vec2(fbm(p * 2.0 + t * 0.3), fbm(p * 2.0 - t * 0.27 + 7.0));
    p += (flow - 0.5) * iViscosity * 0.6;

    float d = 100.0;
    vec3 accTex = vec3(0.0);
    float accLight = 0.0;

    float iter = 5.0;
    float scale = 1.5 + (iAmplitude * 0.5);

    for (float i = 0.0; i < iter; i++) {
        // soft fold instead of abs() for more "liquid" feel
        p = mix(abs(p), p * sign(sin(p * 2.5 + t)), 0.45);
        p -= 0.22 * iAmplitude;
        p *= rot(t * 0.18 + iRotation + i * 0.4);
        p *= scale;

        vec2 texUV = p * 0.5 + 0.5;
        texUV += vec2(sin(t * 0.7 + i * 1.3), cos(t * 0.6 + i)) * 0.06;
        vec3 tex = mxTexture(samp, texUV).rgb;

        float w = 1.0 / (i + 1.0);
        accTex += tex * w;

        float dist = length(p);
        d = min(d, dist);
        accLight += exp(-9.0 * abs(dist - 0.55));
    }
    accTex /= 1.7;

    vec3 pal = palette(d * 0.6 + length(p) * 0.08 + t * 0.18);
    vec3 col = mix(accTex, pal, 0.45 * iSaturation);
    col += pal * accLight * 0.55 * iContrast;
    // wet sheen
    col += vec3(0.05, 0.07, 0.10) * smoothstep(0.0, 0.3, accLight);
    return pow(col, vec3(1.08));
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
    float t = time_f * (0.1 + iFrequency * 0.2) * (1.0 + 0.6 * beat);

    vec3 col = liquidFractal(uv, center, t);

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
