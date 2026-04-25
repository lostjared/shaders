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
const float iFrequency  = 1.0;
const float iBrightness = 1.0;
const float iContrast   = 1.20;
const float iSaturation = 1.40;
const float iHueShift   = 0.50;
const float iZoom       = 1.0;
const float iRotation   = 0.0;
const float iInkWeight  = 1.10;

vec3 palette(float t) {
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(1.0, 0.7, 1.3);
    vec3 d = vec3(0.10, 0.30, 0.55);
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
    p = fract(p * vec2(43.13, 27.91));
    p += dot(p, p + 22.7);
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
    for (int i = 0; i < 6; ++i) { v += a * vnoise(p); p *= 2.05; a *= 0.5; }
    return v;
}

// 4-channel ink that diffuses through a fractal field
vec3 inkBloom(vec2 uv, vec2 center, float t) {
    vec2 p = uv - center;
    p.x *= iResolution.x / iResolution.y;
    p /= 0.5 + iZoom * 2.0;

    // domain warp drives the ink-spread
    vec2 q = vec2(fbm(p * 1.7 + t * 0.20), fbm(p * 1.7 + 3.5 - t * 0.18));
    vec2 r = vec2(fbm(p * 1.7 + 4.0 * q + t * 0.12),
                  fbm(p * 1.7 + 4.0 * q + 9.1 - t * 0.10));
    vec2 pp = p + (r - 0.5) * 0.55 * iAmplitude;

    // fractal accumulation
    vec3 accTex = vec3(0.0);
    float ring = 100.0;
    float scale = 1.55 + iAmplitude * 0.4;
    for (float i = 0.0; i < 5.0; i++) {
        pp = abs(pp) - 0.20;
        pp *= rot(t * 0.18 + iRotation + i * 0.55);
        pp *= scale;
        ring = min(ring, abs(length(pp) - 0.55));
        vec2 texUV = pp * 0.5 + 0.5;
        accTex += mxTexture(samp, texUV).rgb * (0.55 / (i + 1.0));
    }
    accTex /= 1.6;

    // four ink "drops" at offset positions, each its own hue
    float d0 = fbm(p * 2.0 - t * 0.13);
    float d1 = fbm(p * 2.0 + 7.0 + t * 0.11);
    float d2 = fbm(p * 2.0 + 13.0 + t * 0.09);
    float d3 = fbm(p * 2.0 + 19.0 - t * 0.10);
    vec3 ink = vec3(0.0);
    ink += palette(0.05) * d0;
    ink += palette(0.30) * d1;
    ink += palette(0.55) * d2;
    ink += palette(0.80) * d3;
    ink *= 0.5 * iInkWeight;

    vec3 col = mix(accTex, ink, 0.55 * iSaturation);
    col += palette(d0 * 0.5 + t * 0.07) * exp(-15.0 * ring) * 0.5 * iContrast;
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
    float t = time_f * (0.07 + iFrequency * 0.20) * (1.0 + 0.6 * beat);

    vec3 col = inkBloom(uv, center, t);

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
