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

// --- COLOR HELPERS ---

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

// Cosine Palette for the "Electric" glow
vec3 palette(float t) {
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(1.0, 1.0, 1.0);
    vec3 d = vec3(0.263, 0.416, 0.557); 
    return a + b * cos(6.28318 * (c * t + d + iHueShift));
}

// --- COORDINATE HELPERS ---

vec2 rotate2D(vec2 p, float a) {
    float c = cos(a); float s = sin(a);
    return mat2(c, -s, s, c) * p;
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
    return textureLod(tex, sampleUV, lod);
}

// --- NOISE & FBM ---

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

// Combined FBM
float fbm(vec2 p, bool ridges) {
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < 4; i++) {
        float n = noise(p);
        if (ridges) n = 1.0 - abs(n * 2.0 - 1.0);
        v += a * n;
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

// --- MERGED LOGIC ---

vec3 sampleMerged(vec2 uv, float t, float strength, vec2 center, vec2 res) {
    float aspect = res.x / res.y;
    vec2 p = (uv - center) * vec2(aspect, 1.0);
    
    // Initial Rotation
    p = rotate2D(p, iRotation);
    float zoom = max(iZoom, 0.001);
    p /= zoom;

    // --- STAGE 1: FLUID SWIRL ---
    float f1 = fbm(p * 2.0 + t * 0.2, false);
    float f2 = fbm(p * 2.5 - t * 0.3, false);
    
    float rLen = length(p);
    float ang = atan(p.y, p.x);
    ang += (f1 * 3.0 + f2) * strength * 0.5; 
    p = vec2(cos(ang), sin(ang)) * rLen;

    // --- STAGE 2: ELECTRIC DOMAIN WARP ---
    vec2 q = vec2(0.0);
    q.x = fbm(p + vec2(0.0, 0.0) + t * 0.1, false);
    q.y = fbm(p + vec2(5.2, 1.3) - t * 0.1, false);

    vec2 r = vec2(0.0);
    r.x = fbm(p + 4.0 * q + vec2(t * 0.2, 9.2), true); 
    r.y = fbm(p + 4.0 * q + vec2(8.3, 2.8), false);

    // Apply warp
    p += r * (0.15 * strength);

    // --- STAGE 3: FRACTAL FOLDING ---
    float slices = 8.0 + 4.0 * sin(t * 0.2);
    p = kaleido(p, slices);
    
    int iterations = 4 + int(iAmplitude * 1.5);
    float scale = 1.2 + (iFrequency * 0.2);
    float shift = 0.1 * strength;
    float rotAng = t * 0.2 + (f1 * 0.5); 
    
    for(int i = 0; i < iterations; i++) {
        p = abs(p);
        p -= shift;
        p *= scale;
        p = rotate2D(p, rotAng + float(i)*0.4);
    }

    // --- COMPOSITION ---

    vec2 finalUV = p * 0.5 + center;
    
    // Chromatic Aberration on Texture
    vec2 chroma = vec2(0.005 * strength * f2, 0.0);
    float red = mxTexture(samp, finalUV + chroma).r;
    float grn = mxTexture(samp, finalUV).g;
    float blu = mxTexture(samp, finalUV - chroma).b;
    
    vec3 texCol = vec3(red, grn, blu);
    
    // --- NO MIXING: ADDITIVE ONLY ---
    
    // 1. Calculate Glow Energy
    float energy = (length(r) * 0.5 + f1 * 0.5);
    
    // Sharpen the curve: high power means black background, bright sparks
    // This prevents the "fog" effect
    float glow = pow(energy, 4.0) * iContrast; 
    
    // 2. Calculate Palette
    vec3 pal = palette(length(p) + t * 0.5);
    
    // 3. Final Composite: Texture + Light
    // The texture is passed through purely. The glow is added on top.
    vec3 finalCol = texCol + (pal * glow * strength);

    return finalCol;
}

void main() {
    vec2 uv = tc;
    uv = wrapUV(uv);

    float ampControl = clamp(iAmplitude, 0.0, 2.0);
    float freqControl = clamp(iFrequency, 0.0, 2.0);

    float t = time_f * (0.2 + freqControl * 0.3);
    float strength = 0.5 + (ampControl * 1.0);

    vec2 center = vec2(0.5);
    if (iMouse.z > 0.0) {
        center = iMouse.xy / iResolution;
    }

    vec3 col = sampleMerged(uv, t, strength, center, iResolution);

    color.rgb = applyColorAdjustments(col);
    color.a = 1.0;
}