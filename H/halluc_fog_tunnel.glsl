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
const float iFrequency  = 0.9;
const float iBrightness = 0.95;
const float iContrast   = 1.10;
const float iSaturation = 0.80;
const float iHueShift   = 0.40;
const float iZoom       = 1.0;
const float iRotation   = 0.0;

vec3 fogPalette(float t) {
    vec3 a = vec3(0.40, 0.45, 0.55);
    vec3 b = vec3(0.30, 0.30, 0.40);
    vec3 c = vec3(1.0, 1.0, 1.0);
    vec3 d = vec3(0.60, 0.65, 0.75);
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
    p = fract(p * vec2(127.1, 311.7));
    p += dot(p, p + 31.7);
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

// "Tunnel of fog" — radial coords + fractal-warp + smoke layer
vec3 fogTunnel(vec2 uv, vec2 center, float t) {
    vec2 p = uv - center;
    p.x *= iResolution.x / iResolution.y;
    p /= 0.5 + iZoom * 2.0;

    // polar
    float r = length(p);
    float a = atan(p.y, p.x);
    // Periodic angular parameterization (cos,sin) avoids the atan2 seam
    // at +/- pi. Depth (forward motion) is encoded via an extra phase
    // offset on the angular vector so 1D fbm input still varies along z.
    float depth = 1.0 / max(r, 0.0001) - t * 0.4;
    const float K = 2.0; // angular frequency (cells around the tunnel)
    vec2 ang = vec2(cos(a), sin(a));

    // fbm fog density along tunnel — continuous across the seam
    float fog  = fbm(ang * K * 1.5 + vec2(depth * 1.5, 0.0));
    float fog2 = fbm(ang * K * 3.0 + vec2(0.0, depth * 3.0) + 5.0);
    fog = mix(fog, fog2, 0.4);
    fog *= smoothstep(0.0, 1.5, 1.5 - r); // fade at edges

    // fractal-warp the camera read
    vec2 pf = p;
    vec3 accTex = vec3(0.0);
    float scale = 1.45 + iAmplitude * 0.35;
    for (float i = 0.0; i < 4.0; i++) {
        pf = abs(pf) - 0.16;
        pf *= rot(t * 0.10 + iRotation + i * 0.6);
        pf *= scale;
        vec2 texUV = pf * 0.5 + 0.5;
        accTex += mxTexture(samp, texUV).rgb * (0.55 / (i + 1.0));
    }

    vec3 pal = fogPalette(fog * 0.7 + r * 0.3 + t * 0.05);
    vec3 col = accTex * (1.0 - fog * 0.85);
    col = mix(col, pal, smoothstep(0.10, 0.95, fog));
    col += pal * pow(1.0 - r, 4.0) * 0.30;     // distant glow
    col *= 1.0 - smoothstep(0.7, 1.6, r) * 0.5; // tunnel falloff
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
    float t = time_f * (0.10 + iFrequency * 0.20) * (1.0 + 0.6 * beat);

    vec3 col = fogTunnel(uv, center, t);

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
