#version 330 core

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform vec4 iMouse;

out vec4 color;
in vec2 tc;

// Controls
const float iAmplitude = 1.0;
const float iFrequency = 1.0;
const float iBrightness = 1.0;
const float iContrast = 1.0;
const float iSaturation = 1.0;
const float iHueShift = 0.0;
const float iZoom = 1.0;
const float iRotation = 0.0;

// --- Helper Functions ---

// IQ's Cosine Palette - standard for psychedelic shaders
vec3 palette(float t) {
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(1.0, 1.0, 1.0);
    vec3 d = vec3(0.263, 0.416, 0.557); // Trippy Blue/Purple/Cyan offset
    return a + b * cos(6.28318 * (c * t + d + iHueShift));
}

vec3 adjustBrightness(vec3 col, float b) { return col * b; }
vec3 adjustContrast(vec3 col, float c) { return (col - 0.5) * c + 0.5; }
vec3 adjustSaturation(vec3 col, float s) {
    float gray = dot(col, vec3(0.299, 0.587, 0.114));
    return mix(vec3(gray), col, s);
}

// Triangle wave wrap function
vec2 wrapUV(vec2 tc) {
    return 1.0 - abs(1.0 - 2.0 * fract(tc * 0.5));
}

vec4 mxTexture(sampler2D tex, vec2 tc) {
    vec2 ts = vec2(textureSize(tex, 0));
    vec2 eps = 0.5 / ts;
    vec2 uv = wrapUV(tc);
    vec2 sampleUV = clamp(uv, eps, 1.0 - eps);
    float lod = 0.0; // Simplified for performance in complex loops
    return textureLod(tex, sampleUV, lod);
}

// --- Procedural Logic ---

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

// 2D Noise
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

// FBM with "Ridge" option for electricity
float fbm(vec2 p, bool ridges) {
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < 4; i++) { // Reduced iterations for perf, increased visual complexity elsewhere
        float n = noise(p);
        if (ridges)
            n = 1.0 - abs(n * 2.0 - 1.0); // Create sharp valleys
        v += a * n;
        p *= 2.05;
        a *= 0.5;
    }
    return v;
}

vec2 kaleido(vec2 p, float slices) {
    float pi = 3.14159265359;
    float r = length(p);
    float a = atan(p.y, p.x);
    float sector = pi * 2.0 / slices;
    a = mod(a, sector);
    a = abs(a - sector * 0.5);
    return vec2(cos(a), sin(a)) * r;
}

// Rotator
mat2 rot(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c);
}

vec3 renderEnergy(vec2 uv, float t, float strength, vec2 center, vec2 res) {
    float aspect = res.x / res.y;
    vec2 p = (uv - center) * vec2(aspect, 1.0);

    // Zoom/Rotate Pre-pass
    p *= rot(iRotation + t * 0.1);
    float zoomLvl = max(iZoom, 0.1);
    p /= zoomLvl;

    // --- Domain Warping (The Psychedelic Melt) ---
    vec2 q = vec2(0.0);
    q.x = fbm(p + vec2(0.0, 0.0) + t * 0.2, false);
    q.y = fbm(p + vec2(5.2, 1.3) - t * 0.15, false);

    vec2 r = vec2(0.0);
    r.x = fbm(p + 4.0 * q + vec2(t * 0.5, 9.2), true); // Ridged noise here for electricity
    r.y = fbm(p + 4.0 * q + vec2(8.3, 2.8), false);

    // Distort the UVs heavily for the kaleidoscope
    vec2 warpedUV = p + strength * r;

    // Dynamic Kaleidoscope slices
    float slices = 6.0 + 10.0 * sin(t * 0.1) * iAmplitude;
    vec2 k = kaleido(warpedUV, max(3.0, slices));

    // --- Texture Sampling ---
    // We sample the texture using the chaotic warped coordinates
    vec2 texUV = k / vec2(aspect, 1.0) + center;
    texUV += r * 0.1; // Add noise offset

    vec3 texCol = mxTexture(samp, texUV).rgb;

    // --- Energy Injection ---
    // Create a "glow" mask based on the magnitude of the distortion
    float warpLen = length(r);

    // 1. Electric ridges: High values in 'r' create bright lines
    float electric = pow(warpLen, 3.0) * iContrast;

    // 2. Color Palette injection
    // Mix the texture color with a procedural palette based on noise
    vec3 pal = palette(length(q) + t * 0.4);

    // Composition
    vec3 finalCol = mix(texCol, pal, 0.5 * iSaturation); // Blend texture and palette

    // Additive mixing for "Light" effect
    finalCol += pal * electric * strength;

    // Sharp white hot core
    finalCol += vec3(smoothstep(0.8, 1.0, electric)) * 2.0;

    return finalCol;
}

void main() {
    vec2 uv = tc;
    uv = wrapUV(uv); // Keep your mirror wrap, it's good for seamlessness

    float t = time_f * (0.2 + iFrequency * 0.5);
    float strength = iAmplitude * 1.5;

    vec2 center = vec2(0.5);
    if (iMouse.z > 0.0) {
        center = iMouse.xy / iResolution;
    }

    // Single pass is usually enough with this level of complexity,
    // but we add a slight chromatic aberration for extra trippiness
    vec3 col;
    vec2 offset = vec2(0.005 * strength, 0.0);

    col.r = renderEnergy(uv + offset, t, strength, center, iResolution).r;
    col.g = renderEnergy(uv, t, strength, center, iResolution).g;
    col.b = renderEnergy(uv - offset, t, strength, center, iResolution).b;

    // Global adjustments
    col = adjustBrightness(col, iBrightness);
    // Contrast is handled partly inside renderEnergy for the glow lines

    // Vignette (darkens corners to focus on the energy)
    vec2 vUV = uv * (1.0 - uv.yx);
    float vig = vUV.x * vUV.y * 15.0;
    vig = pow(vig, 0.25);
    col *= vig;

    color = vec4(col, 1.0);
}