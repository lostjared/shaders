#version 330 core

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform vec4 iMouse;

out vec4 color;
in vec2 tc;

// Controls
const float iAmplitude  = 1.0;
const float iFrequency  = 1.0;
const float iBrightness = 1.0;
const float iContrast   = 1.0;
const float iSaturation = 1.0;
const float iHueShift   = 0.0;
const float iZoom       = 1.0;
const float iRotation   = 0.0;

// --- Color Helpers ---

vec3 adjustBrightness(vec3 col, float b) { return col * b; }
vec3 adjustContrast(vec3 col, float c) { return (col - 0.5) * c + 0.5; }
vec3 adjustSaturation(vec3 col, float s) {
    float gray = dot(col, vec3(0.299, 0.587, 0.114));
    return mix(vec3(gray), col, s);
}
vec3 rotateHue(vec3 col, float angle) {
    float U = cos(angle); float W = sin(angle);
    mat3 R = mat3(
        0.299+0.701*U+0.168*W, 0.587-0.587*U+0.330*W, 0.114-0.114*U-0.497*W,
        0.299-0.299*U-0.328*W, 0.587+0.413*U+0.035*W, 0.114-0.114*U+0.292*W,
        0.299-0.300*U+1.250*W, 0.587-0.588*U-1.050*W, 0.114+0.886*U-0.203*W
    );
    return clamp(R * col, 0.0, 1.0);
}
vec3 applyColorAdjustments(vec3 col) {
    col = adjustBrightness(col, iBrightness);
    col = adjustContrast(col, iContrast);
    col = adjustSaturation(col, iSaturation);
    col = rotateHue(col, iHueShift);
    return clamp(col, 0.0, 1.0);
}

// --- Coordinate Helpers ---

vec2 applyZoomRotation(vec2 uv, vec2 center) {
    vec2 p = uv - center;
    float c = cos(iRotation); float s = sin(iRotation);
    p = mat2(c, -s, s, c) * p;
    float z = max(abs(iZoom), 0.001);
    p /= z;
    return p + center;
}

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
    if (deriv.x > 0.0 || deriv.y > 0.0) lod = log2(max(max(deriv.x, deriv.y) * max(ts.x, ts.y), 1.0));
    return textureLod(tex, sampleUV, lod);
}

// --- NOISE Functions (Restored for Liquid Effect) ---

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
    for (int i = 0; i < 4; i++) { // Reduced iterations slightly for speed
        v += a * noise(p);
        p *= 2.0;
        a *= 0.5;
    }
    return v;
}

// --- Fractal Logic ---

vec2 rotate2D(vec2 p, float a) {
    float c = cos(a); float s = sin(a);
    return mat2(c, -s, s, c) * p;
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

// Hybird: Liquid movement + Geometric Folding
vec3 sampleLiquidFractal(vec2 uv, float t, float strength, vec2 center, vec2 res) {
    float aspect = res.x / res.y; 
    
    float ampControl  = clamp(iAmplitude,  0.0, 2.0);
    float freqControl = clamp(iFrequency, 0.0, 2.0);

    vec2 p = (uv - center) * vec2(aspect, 1.0);
    
    // --- LIQUID INJECTION ---
    // We calculate a flow field based on noise
    // We disturb 'p' BEFORE it enters the kaleidoscope/fractal loop
    float n1 = fbm(p * 3.0 + t * 0.4);
    float n2 = fbm(p * 2.0 - t * 0.3);
    
    vec2 flow = vec2(cos(n1 * 6.0), sin(n2 * 6.0));
    
    // Add liquid wobble to the coordinates
    // strength * 0.1 ensures it doesn't destroy the shape, just ripples it
    p += flow * (0.05 + 0.1 * strength); 

    // --- GEOMETRIC FRACTAL ---
    
    // 1. Kaleidoscope
    float slices = 6.0 + floor(ampControl * 4.0);
    p = kaleido(p, slices);
    
    // 2. Iterative Folding
    int iterations = 4 + int(ampControl * 2.0); 
    float scale = 1.2 + (freqControl * 0.5);
    float shift = 0.1 * strength;
    float angle = t * 0.1;
    
    for(int i = 0; i < iterations; i++) {
        p = abs(p);
        p -= shift;
        p *= scale;
        p = rotate2D(p, angle + float(i)*0.5 + n1*0.2); // Add noise to rotation too
    }
    
    // 3. Map back to Texture
    // We add the flow again at the end for "surface water" feel
    vec2 finalUV = p * 0.5 + center + (flow * 0.02);
    
    // Chromatic aberration based on flow intensity
    float chroma = 0.005 * strength * (1.0 + n1);
    
    float r = mxTexture(samp, finalUV + vec2(chroma, 0.0)).r;
    float g = mxTexture(samp, finalUV).g;
    float b = mxTexture(samp, finalUV - vec2(chroma, 0.0)).b;
    
    return vec3(r, g, b);
}

void main() {
    vec2 uv = tc;
    uv = wrapUV(uv);
    uv = applyZoomRotation(uv, vec2(0.5));

    float ampControl  = clamp(iAmplitude,  0.0, 2.0);
    
    float tSpeed   = 0.3; 
    float t        = time_f * tSpeed;
    float strength = 0.5 + (ampControl * 0.5);

    vec2 center = vec2(0.5);
    if (iMouse.z > 0.0) {
        center = iMouse.xy / iResolution;
    }

    vec3 col = sampleLiquidFractal(uv, t, strength, center, iResolution);

    color.rgb = applyColorAdjustments(col);
    color.a = 1.0;
}