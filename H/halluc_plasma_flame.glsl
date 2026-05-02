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
const float iContrast = 1.15;
const float iSaturation = 1.30;
const float iHueShift = 0.10;
const float iZoom = 1.0;
const float iRotation = 0.0;

// "Plasma flame" — looks like fire but in shifting acid hues
vec3 acidFlamePalette(float t) {
    t = clamp(t, 0.0, 1.0);
    vec3 c1 = vec3(0.05, 0.0, 0.20);
    vec3 c2 = vec3(0.85, 0.10, 0.55);
    vec3 c3 = vec3(1.00, 0.55, 0.05);
    vec3 c4 = vec3(0.40, 1.10, 0.30);
    vec3 c5 = vec3(0.85, 1.20, 1.00);
    if (t < 0.30)
        return mix(c1, c2, t / 0.30);
    if (t < 0.60)
        return mix(c2, c3, (t - 0.30) / 0.30);
    if (t < 0.85)
        return mix(c3, c4, (t - 0.60) / 0.25);
    return mix(c4, c5, (t - 0.85) / 0.15);
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

float hash21(vec2 p) {
    p = fract(p * vec2(83.41, 27.93));
    p += dot(p, p + 21.7);
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
    for (int i = 0; i < 6; ++i) {
        v += a * vnoise(p);
        p *= 2.05;
        a *= 0.5;
    }
    return v;
}

vec3 plasmaFlame(vec2 uv, vec2 center, float t) {
    vec2 p = uv - center;
    p.x *= iResolution.x / iResolution.y;
    p /= 0.5 + iZoom * 2.0;

    // domain warp
    vec2 q = vec2(fbm(p + t * 0.2), fbm(p + 5.2 - t * 0.17));
    vec2 r = vec2(fbm(p + 4.0 * q + 1.7 + t * 0.15),
                  fbm(p + 4.0 * q + 9.2 - t * 0.13));
    float h = fbm(p + 4.0 * r);

    // fractal accumulation drives the structure
    float ring = 100.0;
    vec3 accTex = vec3(0.0);
    vec2 pf = p;
    float scale = 1.55 + iAmplitude * 0.4;
    for (float i = 0.0; i < 4.0; i++) {
        pf = abs(pf) - 0.22;
        pf *= rot(t * 0.18 + iRotation + i);
        pf *= scale;
        ring = min(ring, abs(length(pf) - 0.55));
        vec2 texUV = pf * 0.5 + 0.5 + (r - 0.5) * 0.08;
        accTex += mxTexture(samp, texUV).rgb / (i + 1.0);
    }

    float heat = clamp(h * 1.4 + 0.25 * iAmplitude, 0.0, 1.5);
    vec3 flame = acidFlamePalette(heat / 1.5);
    vec3 col = mix(accTex * 0.7, flame, smoothstep(0.10, 0.95, heat));
    col += flame * exp(-25.0 * ring) * iContrast;
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
    float t = time_f * (0.08 + iFrequency * 0.22) * (1.0 + 0.6 * beat);

    vec3 col = plasmaFlame(uv, center, t);

    float gray = dot(col, vec3(0.299, 0.587, 0.114));
    col = mix(vec3(gray), col, iSaturation);
    col = (col - 0.5) * iContrast + 0.5;
    col += vec3(0.6, 0.4, 1.0) * treble * 0.18;
    col *= iBrightness * (1.0 + 0.5 * bass);

    vec2 vUV = uv * (1.0 - uv.yx);
    float vig = pow(vUV.x * vUV.y * 15.0, 0.20);
    col *= vig;

    color = vec4(col, 1.0);
}
