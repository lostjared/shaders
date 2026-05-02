#version 330 core

out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform vec4 iMouse;
const float PI = 3.14159265359;
// --- CONTROLS ---

float pingPong(float x, float length) {
    float modVal = mod(x, length * 2.0);
    return modVal <= length ? modVal : length * 2.0 - modVal;
}

const float iAmplitude = 0.5;
const float iFrequency = 1.5;
const float iBrightness = 0.8;
const float iContrast = 1.1;
const float iSaturation = 0.5; // slightly lowered default so texture pops
const float iZoom = 1.0;
float iRotation = pingPong(time_f, 10.0);

// --- RAINBOW COLOR FUNCTION ---
vec3 rainbow(float t) {
    t = fract(t);
    float r = abs(t * 6.0 - 3.0) - 1.0;
    float g = 2.0 - abs(t * 6.0 - 2.0);
    float b = 2.0 - abs(t * 6.0 - 4.0);
    return clamp(vec3(r, g, b), 0.0, 1.0);
}

// --- HELPERS ---
vec3 adjustBrightness(vec3 col, float b) { return col * b; }
vec3 adjustContrast(vec3 col, float c) { return (col - 0.5) * c + 0.5; }
vec3 adjustSaturation(vec3 col, float s) {
    float gray = dot(col, vec3(0.299, 0.587, 0.114));
    return mix(vec3(gray), col, s);
}

vec2 wrapUV(vec2 tc) {
    return 1.0 - abs(1.0 - 2.0 * fract(tc * 0.5));
}

vec4 mxTexture(sampler2D tex, vec2 tc) {
    vec2 ts = vec2(textureSize(tex, 0));
    vec2 eps = 0.5 / ts;
    vec2 uv = wrapUV(tc);
    vec2 sampleUV = clamp(uv, eps, 1.0 - eps);
    return texture(tex, sampleUV);
}

vec2 rotate2D(vec2 p, float a) {
    float c = cos(a);
    float s = sin(a);
    return mat2(c, -s, s, c) * p;
}

// --- NOISE ---
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    float a = hash(i + vec2(0.0, 0.0));
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p, bool ridges) {
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < 4; i++) {
        float n = noise(p);
        if (ridges)
            n = 1.0 - abs(n * 2.0 - 1.0);
        v += a * n;
        p *= 2.05;
        a *= 0.5;
    }
    return v;
}

vec2 kaleido(vec2 p, float slices) {
    float r = length(p);
    float a = atan(p.y, p.x);
    float sector = PI * 2.0 / slices;
    a = mod(a, sector);
    a = abs(a - sector * 0.5);
    return vec2(cos(a), sin(a)) * r;
}

// --- CORE EFFECT ---

vec3 sampleLiquidRainbow(vec2 uv, float t, float strength, vec2 center, vec2 res) {
    float aspect = res.x / res.y;
    vec2 p = (uv - center) * vec2(aspect, 1.0);

    // 1. Initial Transform
    p = rotate2D(p, iRotation);
    float zoom = max(iZoom, 0.01);
    p /= zoom;

    // 2. WARP ENGINE
    vec2 q = vec2(0.0);
    q.x = fbm(p + vec2(0.0, 0.0) + t * 0.1, false);
    q.y = fbm(p + vec2(5.2, 1.3) - t * 0.1, false);

    vec2 r = vec2(0.0);
    r.x = fbm(p + 4.0 * q + vec2(t * 0.2, 9.2), true);
    r.y = fbm(p + 4.0 * q + vec2(8.3, 2.8), false);

    p += r * (0.15 * strength);

    // 3. FRACTAL FOLDING
    float slices = 6.0 + floor(iAmplitude * 4.0);
    p = kaleido(p, slices);

    int iterations = 4 + int(iAmplitude * 1.5);
    float scale = 1.1 + (iFrequency * 0.3);
    float shift = 0.1 * strength;
    float angle = t * 0.2;

    for (int i = 0; i < iterations; i++) {
        p = abs(p);
        p -= shift;
        p *= scale;
        p = rotate2D(p, angle + float(i) * 0.5 + (r.x * 0.2));
    }

    // 4. COLOR CALCULATION
    float spiralAngle = atan(p.y, p.x);
    float colorIndex = (spiralAngle / (2.0 * PI)) + length(p) * 0.5 + t * 0.5;
    vec3 rainbowCol = rainbow(colorIndex);

    // 5. COMPOSITION (MODIFIED)

    // A. Sample the texture using the warped 'p' coordinate
    // This applies the liquid shape to the texture image
    vec2 finalUV = p * 0.5 + center;
    vec3 texCol = mxTexture(samp, finalUV).rgb;

    // B. Calculate "Electric" glow intensity
    float electric = pow(length(r), 3.0) * iContrast;

    // C. BLEND: Tint the Texture
    // We calculate the luminance (brightness) of the texture
    float texLum = dot(texCol, vec3(0.299, 0.587, 0.114));

    // Create a "Colorized" version:
    // Uses the Texture's brightness but the Rainbow's color.
    // Multiplied by 2.0 to ensure it glows rather than darkening.
    vec3 colorizedTex = rainbowCol * texLum * 2.5;

    // Mix the original texture color with the colorized version
    // iSaturation now controls how much of the rainbow tint applies
    vec3 finalCol = mix(texCol, colorizedTex, iSaturation);

    // D. Add the glowing electric ridges on top
    finalCol += rainbowCol * electric * strength;

    return finalCol;
}

void main() {
    vec2 uv = tc;
    uv = wrapUV(uv);

    float t = time_f * (0.2 + iFrequency * 0.1);
    float ampControl = clamp(iAmplitude, 0.0, 2.0);
    float strength = 0.5 + (ampControl * 1.0);

    vec2 center = vec2(0.5);
    if (iMouse.z > 0.0) {
        center = iMouse.xy / iResolution;
    }

    vec2 offset = vec2(0.003 * strength, 0.0);

    vec3 col;
    col.r = sampleLiquidRainbow(uv + offset, t, strength, center, iResolution).r;
    col.g = sampleLiquidRainbow(uv, t, strength, center, iResolution).g;
    col.b = sampleLiquidRainbow(uv - offset, t, strength, center, iResolution).b;

    // Post Processing
    col = adjustBrightness(col, iBrightness);
    col = adjustContrast(col, iContrast);

    // Vignette
    vec2 vUV = uv * (1.0 - uv.yx);
    float vig = vUV.x * vUV.y * 15.0;
    vig = pow(vig, 0.15);
    col *= vig;

    // Pulse
    float pulse = 0.85 + 0.15 * sin(time_f * 2.0);
    color = vec4(col * pulse, 1.0);
}