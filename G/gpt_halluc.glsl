#version 330 core

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform vec4 iMouse;

out vec4 color;
in vec2 tc; // Input UVs from the 3D Mesh

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

vec3 adjustBrightness(vec3 col, float b) {
    return col * b;
}

vec3 adjustContrast(vec3 col, float c) {
    return (col - 0.5) * c + 0.5;
}

vec3 adjustSaturation(vec3 col, float s) {
    float gray = dot(col, vec3(0.299, 0.587, 0.114));
    return mix(vec3(gray), col, s);
}

vec3 rotateHue(vec3 col, float angle) {
    float U = cos(angle);
    float W = sin(angle);
    mat3 R = mat3(
        0.299 + 0.701 * U + 0.168 * W,
        0.587 - 0.587 * U + 0.330 * W,
        0.114 - 0.114 * U - 0.497 * W,
        0.299 - 0.299 * U - 0.328 * W,
        0.587 + 0.413 * U + 0.035 * W,
        0.114 - 0.114 * U + 0.292 * W,
        0.299 - 0.300 * U + 1.250 * W,
        0.587 - 0.588 * U - 1.050 * W,
        0.114 + 0.886 * U - 0.203 * W);
    return clamp(R * col, 0.0, 1.0);
}

vec3 applyColorAdjustments(vec3 col) {
    col = adjustBrightness(col, iBrightness);
    col = adjustContrast(col, iContrast);
    col = adjustSaturation(col, iSaturation);
    col = rotateHue(col, iHueShift);
    return clamp(col, 0.0, 1.0);
}

vec2 applyZoomRotation(vec2 uv, vec2 center) {
    vec2 p = uv - center;
    float c = cos(iRotation);
    float s = sin(iRotation);
    p = mat2(c, -s, s, c) * p;
    float z = max(abs(iZoom), 0.001);
    p /= z;
    return p + center;
}

// Triangle wave wrap function: turns 0..1 into a seamless mirror pattern
vec2 wrapUV(vec2 tc) {
    return 1.0 - abs(1.0 - 2.0 * fract(tc * 0.5));
}

vec4 mxTexture(sampler2D tex, vec2 tc) {
    vec2 ts = vec2(textureSize(tex, 0));
    vec2 eps = 0.5 / ts;

    vec2 uv = wrapUV(tc);
    vec2 sampleUV = clamp(uv, eps, 1.0 - eps);

    float lod = 0.0;
    vec2 deriv = fwidth(tc);
    if (deriv.x > 0.0 || deriv.y > 0.0) {
        lod = log2(max(max(deriv.x, deriv.y) * max(ts.x, ts.y), 1.0));
    }

    return textureLod(tex, sampleUV, lod);
}

// --- Procedural Logic ---

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

float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < 5; i++) {
        v += a * noise(p);
        p *= 2.1;
        a *= 0.55;
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

vec3 sampleWarp(vec2 uv, float t, float strength, vec2 center, vec2 res) {
    // If mapping to a mesh with square texture, you might want to force aspect to 1.0
    // float aspect = 1.0;
    float aspect = res.x / res.y;

    float ampControl = clamp(iAmplitude, 0.0, 2.0);
    float freqControl = clamp(iFrequency, 0.0, 2.0);

    vec2 p = (uv - center) * vec2(aspect, 1.0);
    float f1 = fbm(p * 1.8 + t * 0.3);
    float f2 = fbm(p.yx * 2.3 - t * 0.25);
    float f3 = fbm(p * 3.1 + vec2(1.3, -0.7) * t * 0.2);

    vec2 swirl = p;
    float r = length(swirl);
    float a = atan(swirl.y, swirl.x);
    a += (f1 * 4.0 + f2 * 2.0) * strength * 0.6;
    swirl = vec2(cos(a), sin(a)) * r;

    float sliceBase = 8.0;
    float sliceRange = 8.0;
    float slices = sliceBase + sliceRange * (0.3 + 0.7 * ampControl) + 4.0 * sin(t * 0.17);

    vec2 k = kaleido(swirl + vec2(f2, f3) * 0.4 * strength, slices);

    vec2 flow = k;
    flow.x += f1 * 0.8 * strength;
    flow.y += (f2 - f3) * 0.8 * strength;

    vec2 base = flow / vec2(aspect, 1.0) + center;
    base = fract(base);

    float chromaBoost = 0.5 + 0.5 * ampControl;
    vec2 chromaShift = 0.0035 * strength * chromaBoost *
                       vec2(sin(t + f1 * 6.0), cos(t * 1.3 + f2 * 6.0));

    float rC = mxTexture(samp, base + chromaShift).r;
    float gC = mxTexture(samp, base).g;
    float bC = mxTexture(samp, base - chromaShift).b;
    vec3 col = vec3(rC, gC, bC);

    float bright = 0.7 + 0.6 * f3 + 0.4 * sin(t * 0.6 + f1 * 3.0);
    bright *= (0.6 + 0.8 * freqControl);

    col *= bright;

    float sat = 1.3 + 0.7 * sin(t * 0.43 + f2 * 5.0);
    sat *= (0.6 + 0.8 * freqControl);

    float gray = dot(col, vec3(0.299, 0.587, 0.114));
    col = mix(vec3(gray), col, sat);

    return col;
}

void main() {
    // 1. Get UVs from the mesh input
    vec2 uv = tc;

    // 2. Apply Mirror Wrapping immediately
    // This makes the UVs "bounce" back and forth (0->1->0) ensuring seamless edges on the mesh
    uv = wrapUV(uv);

    // 3. Apply Zoom/Rotation to the wrapped UVs
    uv = applyZoomRotation(uv, vec2(0.5));

    float ampControl = clamp(iAmplitude, 0.0, 2.0);
    float freqControl = clamp(iFrequency, 0.0, 2.0);

    float tSpeed = 0.3 + 1.7 * (freqControl * 0.5);
    float t = time_f * tSpeed;
    float strength = 0.6 + 1.6 * (ampControl * 0.5);

    vec2 center = vec2(0.5);

    // Check if mouse button is pressed (z > 0)
    if (iMouse.z > 0.0) {
        center = iMouse.xy / iResolution;
    }

    // Pass the wrapped 'uv' to the warping function
    vec3 colA = sampleWarp(uv, t, strength, center, iResolution);
    vec3 colB = sampleWarp(uv + vec2(0.01, -0.007),
                           t + 3.14,
                           strength * 0.9,
                           center,
                           iResolution);

    float blend = 0.5 + 0.5 * sin(t * 0.25);
    vec3 col = mix(colA, colB, blend);

    color.rgb = applyColorAdjustments(col);
    color.a = 1.0;
}