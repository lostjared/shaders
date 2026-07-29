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

// --- COLOR HELPER FUNCTIONS ---

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

// IQ Cosine Palette (from Shader 2)
vec3 palette(float t) {
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(1.0, 1.0, 1.0);
    vec3 d = vec3(0.263, 0.416, 0.557); 
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
    vec2 sampleUV = clamp(uv, eps, 1.0 - eps);
    float lod = 0.0;
    return textureLod(tex, sampleUV, lod);
}

vec2 rotate2D(vec2 p, float a) {
    float c = cos(a); float s = sin(a);
    return mat2(c, -s, s, c) * p;
}

// --- NOISE & WARP FUNCTIONS ---

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

// Combined FBM: Can do smooth liquid or sharp ridges
float fbm(vec2 p, bool ridges) {
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < 4; i++) { 
        float n = noise(p);
        if (ridges) n = 1.0 - abs(n * 2.0 - 1.0); 
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

// --- HYBRID RENDER LOGIC ---

vec3 sampleHybrid(vec2 uv, float t, float strength, vec2 center, vec2 res) {
    float aspect = res.x / res.y;
    vec2 p = (uv - center) * vec2(aspect, 1.0);
    
    // 1. Initial Zoom/Rot (Shader 1 style)
    p = rotate2D(p, iRotation);
    float zoom = max(iZoom, 0.01);
    p /= zoom;

    // 2. DOMAIN WARPING (The "Electric" part from Shader 2)
    // We use this to distort the space BEFORE the fractal folding
    vec2 q = vec2(0.0);
    q.x = fbm(p + vec2(0.0, 0.0) + t * 0.1, false);
    q.y = fbm(p + vec2(5.2, 1.3) - t * 0.1, false);

    vec2 r = vec2(0.0);
    r.x = fbm(p + 4.0 * q + vec2(t * 0.2, 9.2), true); // Ridges = True for electric feel
    r.y = fbm(p + 4.0 * q + vec2(8.3, 2.8), false);

    // Apply the warp to p
    // strength controls how much the "electricity" melts the geometry
    p += r * (0.1 * strength);

    // 3. FRACTAL FOLDING (The "Structure" part from Shader 1)
    
    // Kaleidoscope Step
    float slices = 6.0 + floor(iAmplitude * 4.0);
    p = kaleido(p, slices);
    
    // Iterative Box Folding
    int iterations = 4 + int(iAmplitude * 1.5); 
    float scale = 1.1 + (iFrequency * 0.3);
    float shift = 0.1 * strength;
    float angle = t * 0.2;
    
    // We inject the noise value 'r.x' into the rotation to make the shape vibrate
    for(int i = 0; i < iterations; i++) {
        p = abs(p);
        p -= shift;
        p *= scale;
        p = rotate2D(p, angle + float(i)*0.5 + (r.x * 0.2)); 
    }

    // 4. TEXTURE & COLOR COMPOSITION
    
    // Map back to UV space
    vec2 finalUV = p * 0.5 + center;
    
    // Sample Texture
    vec3 texCol = mxTexture(samp, finalUV).rgb;
    
    // Generate Electric Glow (Shader 2 Logic)
    // We use the magnitude of the warp 'r' to create glowing lines
    float electric = pow(length(r), 3.0) * iContrast; 
    
    // Generate Palette
    vec3 pal = palette(length(p) + length(q) + t);
    
    // Mix: Texture provides the base, Palette provides the neon energy
    vec3 finalCol = mix(texCol, pal, 0.4 * iSaturation);
    
    // Additive glow on top
    finalCol += pal * electric * strength;
    
    return finalCol;
}

void main() {
    vec2 uv = tc;
    uv = wrapUV(uv);
    
    float t = time_f * (0.2 + iFrequency * 0.2);
    float ampControl = clamp(iAmplitude, 0.0, 2.0);
    float strength = 0.5 + (ampControl * 1.0);
    
    vec2 center = vec2(0.5);
    if (iMouse.z > 0.0) {
        center = iMouse.xy / iResolution;
    }

    // Chromatic Aberration applied to the Hybrid function
    // We offset the start position for each channel
    vec2 offset = vec2(0.003 * strength, 0.0);
    
    vec3 col;
    col.r = sampleHybrid(uv + offset, t, strength, center, iResolution).r;
    col.g = sampleHybrid(uv,          t, strength, center, iResolution).g;
    col.b = sampleHybrid(uv - offset, t, strength, center, iResolution).b;

    // Post Processing
    col = adjustBrightness(col, iBrightness);
    col = adjustContrast(col, iContrast);
    col = adjustSaturation(col, iSaturation);
    
    // Vignette (from Shader 2)
    vec2 vUV = uv * (1.0 - uv.yx); 
    float vig = vUV.x * vUV.y * 15.0; 
    vig = pow(vig, 0.15); // Softer vignette
    col *= vig;

    color = vec4(col, 1.0);
}