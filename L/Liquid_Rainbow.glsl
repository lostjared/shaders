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
const float iBrightness = 1.2; // Slightly boosted for light effect
const float iContrast = 1.1;
const float iSaturation = 1.2;
const float iHueShift = 0.0;
const float iZoom = 1.0;
const float iRotation = 0.0;

// --- COLOR HELPER FUNCTIONS ---

vec3 adjustBrightness(vec3 col, float b) { return col * b; }
vec3 adjustContrast(vec3 col, float c) { return (col - 0.5) * c + 0.5; }
vec3 adjustSaturation(vec3 col, float s) {
    float gray = dot(col, vec3(0.299, 0.587, 0.114));
    return mix(vec3(gray), col, s);
}

// IQ Cosine Palette - Tweaked for Full Rainbow
vec3 palette(float t) {
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(1.0, 1.0, 1.0);
    // This offset vector creates the rainbow spectrum
    vec3 d = vec3(0.00, 0.33, 0.67);
    return a + b * cos(6.28318 * (c * t + d + iHueShift));
}

// --- COORDINATE HELPERS ---

vec2 wrapUV(vec2 tc) {
    return 1.0 - abs(1.0 - 2.0 * fract(tc * 0.5));
}

vec4 mxTexture(sampler2D tex, vec2 tc) {
    vec2 ts = vec2(textureSize(tex, 0));
    vec2 eps = 0.5 / ts;
    vec2 uv = wrapUV(tc);
    // Smooth wrapping prevents hard edges in the liquid
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

// Standard FBM (Smooth, not ridged, for liquid feel)
float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    mat2 rot = mat2(cos(0.5), sin(0.5), -sin(0.5), cos(0.50));
    for (int i = 0; i < 5; i++) {
        v += a * noise(p);
        p = rot * p * 2.0 + vec2(2.0); // Rotate to prevent axis artifacts
        a *= 0.5;
    }
    return v;
}

// --- LIQUID LIGHT LOGIC ---

vec3 sampleLiquid(vec2 uv, float t, float strength, vec2 center, vec2 res) {
    float aspect = res.x / res.y;
    vec2 p = (uv - center) * vec2(aspect, 1.0);

    // 1. Initial Transform
    p = rotate2D(p, iRotation);
    float zoom = max(iZoom, 0.1);
    p /= zoom;

    // 2. RECURSIVE DOMAIN WARPING (The Liquid Core)
    // We warp the coordinates (q), then warp the warp (r)

    vec2 q = vec2(0.0);
    q.x = fbm(p + vec2(0.0, 0.0) + 0.05 * t);
    q.y = fbm(p + vec2(5.2, 1.3) + 0.05 * t);

    vec2 r = vec2(0.0);
    // Warp 'r' using 'q'
    r.x = fbm(p + 4.0 * q + vec2(t * 0.15));
    r.y = fbm(p + 4.0 * q + vec2(t * 0.05, 2.8));

    // 'f' is the final noise value used for coloring intensity
    float f = fbm(p + 4.0 * r);

    // 3. TEXTURE SAMPLING
    // We use the warped vector 'r' to displace the texture UVs.
    // This makes the image look like it's reflecting in flowing water.
    vec2 fluidUV = uv + (r * 0.2 * strength * iAmplitude);
    vec3 texCol = mxTexture(samp, fluidUV).rgb;

    // 4. COLORING (Rainbow Light)

    // Create the rainbow based on the noise magnitude and time
    // length(q) gives us the "bands" of the oil spill
    vec3 rainbow = palette(length(q) + f + t * 0.2);

    // 5. COMPOSITION

    // Mix the texture with the rainbow
    // The texture acts as the "base matter", the rainbow is the "light"
    vec3 col = mix(texCol, texCol * rainbow * 1.5, 0.6 * iSaturation);

    // Add specular highlights (The "Liquid Light" shine)
    // When the curvature (f) is high, we add pure light
    float shine = f * f * f * 1.5 * iContrast;
    col += shine * rainbow * strength;

    // Deepen the darks to make the lights pop
    col *= 0.8 + 0.5 * f;

    return col;
}

void main() {
    vec2 uv = tc;
    uv = wrapUV(uv);

    // Slow down time for viscous liquid feel
    float t = time_f * (0.1 + iFrequency * 0.1);

    float ampControl = clamp(iAmplitude, 0.0, 2.0);
    float strength = 1.0 + (ampControl * 0.5);

    vec2 center = vec2(0.5);
    if (iMouse.z > 0.0) {
        center = iMouse.xy / iResolution;
    }

    // Chromatic Aberration
    // We separate the channels slightly based on the noise intensity
    vec2 offset = vec2(0.005 * strength, 0.0);

    vec3 col;
    col.r = sampleLiquid(uv + offset, t, strength, center, iResolution).r;
    col.g = sampleLiquid(uv, t, strength, center, iResolution).g;
    col.b = sampleLiquid(uv - offset, t, strength, center, iResolution).b;

    // Post Processing
    col = adjustBrightness(col, iBrightness);
    col = adjustContrast(col, iContrast);
    col = adjustSaturation(col, iSaturation);

    // Vignette
    vec2 vUV = uv * (1.0 - uv.yx);
    float vig = vUV.x * vUV.y * 15.0;
    vig = pow(vig, 0.15);
    col *= vig;

    color = vec4(col, 1.0);
}