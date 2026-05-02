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
const float iBrightness = 1.05;
const float iContrast = 1.20;
const float iSaturation = 1.40;
const float iHueShift = 0.0;
const float iZoom = 1.0;
const float iRotation = 0.0;
const float iEmberDensity = 1.10;

vec3 firePalette(float t) {
    t = clamp(t, 0.0, 1.0);
    vec3 c1 = vec3(0.10, 0.0, 0.0);
    vec3 c2 = vec3(0.70, 0.10, 0.05);
    vec3 c3 = vec3(1.20, 0.50, 0.10);
    vec3 c4 = vec3(1.30, 1.00, 0.40);
    if (t < 0.40)
        return mix(c1, c2, t / 0.40);
    if (t < 0.75)
        return mix(c2, c3, (t - 0.40) / 0.35);
    return mix(c3, c4, (t - 0.75) / 0.25);
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
    p = fract(p * vec2(127.1, 311.7));
    p += dot(p, p + 19.31);
    return fract(p.x * p.y);
}

vec3 emberStorm(vec2 uv, vec2 center, float t) {
    vec2 p = uv - center;
    p.x *= iResolution.x / iResolution.y;
    p /= 0.5 + iZoom * 2.0;

    // Fractal background flicker
    vec3 bg = vec3(0.0);
    vec2 pf = p;
    for (float i = 0.0; i < 4.0; i++) {
        pf = abs(pf) - 0.20;
        pf *= rot(t * 0.10 + iRotation + i * 0.5);
        pf *= 1.5 + iAmplitude * 0.3;
        vec2 texUV = pf * 0.5 + 0.5;
        bg += mxTexture(samp, texUV).rgb * (0.5 / (i + 1.0));
    }
    bg *= 0.55;

    // Particle field of embers (cellular)
    float emberLight = 0.0;
    vec3 emberCol = vec3(0.0);
    vec2 grid = p * (4.0 + iAmplitude * 2.0);
    vec2 gi = floor(grid);
    vec2 gf = fract(grid) - 0.5;
    for (int dy = -1; dy <= 1; ++dy) {
        for (int dx = -1; dx <= 1; ++dx) {
            vec2 nb = vec2(float(dx), float(dy));
            vec2 cell = gi + nb;
            float h = hash21(cell);
            float life = fract(h * 13.7 + t * (0.30 + 0.40 * h));
            // ember position drifts upward and jitters
            vec2 jitter = vec2(
                hash21(cell + 1.7) - 0.5,
                hash21(cell + 5.3) - 0.5);
            vec2 pos = nb + jitter * 0.6 + vec2(0.0, -life * 1.0);
            float d = length(gf - pos);
            float spark = exp(-22.0 * d) * (1.0 - life) * iEmberDensity;
            emberLight += spark;
            float heat = mix(0.4, 1.0, h) * (1.0 - life * 0.7);
            emberCol += firePalette(heat) * spark;
        }
    }

    // Heat shimmer warp on bg
    bg = mxTexture(samp, p * 0.4 + 0.5 + vec2(0.0, sin(p.x * 8.0 + t * 2.0) * 0.01)).rgb * 0.3 + bg;

    vec3 col = bg * 0.5 + emberCol * iContrast;
    col += firePalette(emberLight * 0.6) * 0.25;
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
    float t = time_f * (0.10 + iFrequency * 0.25) * (1.0 + 0.6 * beat);

    vec3 col = emberStorm(uv, center, t);

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
