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
const float iSaturation = 1.20;
const float iHueShift = 0.0;
const float iZoom = 1.0;
const float iRotation = 0.0;
const float iLavaHeat = 1.0;

vec3 lavaPalette(float t) {
    t = clamp(t, 0.0, 1.0);
    vec3 c1 = vec3(0.04, 0.0, 0.0);
    vec3 c2 = vec3(0.45, 0.05, 0.02);
    vec3 c3 = vec3(0.95, 0.30, 0.05);
    vec3 c4 = vec3(1.20, 0.85, 0.20);
    if (t < 0.30)
        return mix(c1, c2, t / 0.30);
    if (t < 0.65)
        return mix(c2, c3, (t - 0.30) / 0.35);
    return mix(c3, c4, (t - 0.65) / 0.35);
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
    p = fract(p * vec2(31.71, 17.13));
    p += dot(p, p + 18.5);
    return fract(p.x * p.y);
}

// Voronoi-like F1/F2 → cracked-crust mask
vec2 voronoi(vec2 p) {
    vec2 ip = floor(p), fp = fract(p);
    float f1 = 8.0, f2 = 8.0;
    for (int dy = -1; dy <= 1; ++dy)
        for (int dx = -1; dx <= 1; ++dx) {
            vec2 nb = vec2(float(dx), float(dy));
            vec2 jit = vec2(hash21(ip + nb), hash21(ip + nb + 19.7));
            vec2 d = nb + jit - fp;
            float r = dot(d, d);
            if (r < f1) {
                f2 = f1;
                f1 = r;
            } else if (r < f2) {
                f2 = r;
            }
        }
    return vec2(sqrt(f1), sqrt(f2));
}

vec3 lavaCrack(vec2 uv, vec2 center, float t) {
    vec2 p = uv - center;
    p.x *= iResolution.x / iResolution.y;
    p /= 0.5 + iZoom * 2.0;

    // fractal warp
    vec2 pf = p;
    vec3 accTex = vec3(0.0);
    float ring = 100.0;
    float scale = 1.55 + iAmplitude * 0.4;
    for (float i = 0.0; i < 4.0; i++) {
        pf = abs(pf) - 0.20;
        pf *= rot(t * 0.10 + iRotation + i * 0.5);
        pf *= scale;
        ring = min(ring, abs(length(pf) - 0.55));
        vec2 texUV = pf * 0.5 + 0.5;
        accTex += mxTexture(samp, texUV).rgb * (0.55 / (i + 1.0));
    }

    // Voronoi crust drifts slowly
    vec2 vp = p * (3.5 + iAmplitude) + vec2(0.0, t * 0.15);
    vec2 v = voronoi(vp);
    float crack = smoothstep(0.0, 0.04, v.y - v.x); // thin crack lines
    float crust = 1.0 - crack;

    // hot lava fills the cracks; crust is blackish accTex
    float heat = clamp(crack * iLavaHeat + 0.15, 0.0, 1.5);
    vec3 lava = lavaPalette(heat / 1.5);
    vec3 cool = accTex * vec3(0.35, 0.30, 0.30);

    vec3 col = mix(cool, lava, crack);
    col += lava * exp(-30.0 * ring) * 0.5 * iContrast;
    // glowing edges between crust plates
    col += lavaPalette(0.95) * smoothstep(0.0, 0.02, v.y - v.x) * 0.0; // (no-op base)
    col += lavaPalette(0.80) * pow(1.0 - smoothstep(0.0, 0.06, v.y - v.x), 4.0) * 0.6;
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
    float t = time_f * (0.07 + iFrequency * 0.20) * (1.0 + 0.6 * beat);

    vec3 col = lavaCrack(uv, center, t);

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
