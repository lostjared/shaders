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
const float iContrast   = 1.2;
const float iSaturation = 1.2;
const float iHueShift   = 0.0;
const float iZoom       = 0.8;
const float iRotation   = 0.0;

// --- COLOR HELPER FUNCTIONS ---

vec3 adjustBrightness(vec3 col, float b) { return col * b; }
vec3 adjustContrast(vec3 col, float c) { return (col - 0.5) * c + 0.5; }
vec3 adjustSaturation(vec3 col, float s) {
    float gray = dot(col, vec3(0.299, 0.587, 0.114));
    return mix(vec3(gray), col, s);
}

// IQ Cosine Palette
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
    return textureLod(tex, sampleUV, 0.0);
}

vec2 rotate2D(vec2 p, float a) {
    float c = cos(a); float s = sin(a);
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
    return mix(mix(hash(i + vec2(0.0, 0.0)), hash(i + vec2(1.0, 0.0)), u.x),
               mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < 4; i++) { 
        v += a * noise(p);
        p *= 2.0;
        a *= 0.5;
    }
    return v;
}

// --- RIPPLE BEND EXPAND LOGIC ---

// Calculates the distortion and returns the modified point + the intensity of distortion
vec3 rippleBendExpand(vec2 p, float t, float strength) {
    float d = length(p);
    
    // 1. EXPAND (Breathing/Pulse)
    float expansion = 1.0 + (sin(t * 2.0) * 0.1 * strength);
    p /= expansion;
    
    // 2. RIPPLE (Sine wave propagation)
    // Frequency increases with distance
    float wavePhase = d * (10.0 * iFrequency) - (t * 5.0);
    float ripple = sin(wavePhase);
    
    // Displace outward based on ripple
    p += (p / (d+0.001)) * ripple * 0.05 * strength;
    
    // 3. BEND (Angular Twist)
    float angle = atan(p.y, p.x);
    // Twist angle based on distance and ripple phase
    float twist = sin(d * 4.0 - t) * 0.5 * strength;
    angle += twist;
    
    // Reconstruct P
    p = vec2(cos(angle), sin(angle)) * length(p);
    
    // Return modified point (xy) and the amount of distortion (z) for "Extraction"
    return vec3(p, abs(ripple) + abs(twist));
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
    
    // Initial Zoom/Rot
    p = rotate2D(p, iRotation);
    float zoom = max(iZoom, 0.01);
    p /= zoom;

    // --- APPLY RIPPLE / BEND / EXPAND ---
    // We capture the distortion intensity in 'distort.z'
    vec3 distort = rippleBendExpand(p, t, strength);
    p = distort.xy;
    float extractMask = distort.z; // This is the "Force" of the bend at this pixel

    // Domain Warping (Noise)
    vec2 q = vec2(fbm(p + t * 0.1), fbm(p + vec2(5.2, 1.3)));
    vec2 r = vec2(fbm(p + 4.0 * q + t * 0.2), fbm(p + q));
    p += r * (0.15 * strength);

    // Fractal Folding (Transform)
    float slices = 8.0; // Fixed slices for stability
    p = kaleido(p, slices);
    
    int iterations = 4; 
    float scale = 1.3;
    float shift = 0.2 * strength;
    
    for(int i = 0; i < iterations; i++) {
        p = abs(p);
        p -= shift;
        p *= scale;
        p = rotate2D(p, t * 0.1 + float(i)); 
    }

    // Map back to UV space for texture
    vec2 finalUV = p * 0.5 + center;
    
    // Sample Texture
    vec3 texCol = mxTexture(samp, finalUV).rgb;
    
    // --- EXTRACT LOGIC ---
    // We use the 'extractMask' (calculated from the bend/ripple earlier)
    // to separate the image into "Energy" and "Matter".
    
    // 1. Define the "Energy" color based on palette
    vec3 energyCol = palette(length(p) * 0.2 + t * 0.5 + extractMask);
    
    // 2. Mix based on how hard the geometry was bent
    // Areas with high distortion get the energy color
    vec3 finalCol = mix(texCol, energyCol, smoothstep(0.2, 1.5, extractMask));
    
    // 3. Additive Glow for the "Extract" effect
    finalCol += energyCol * extractMask * 0.5 * strength;
    
    return finalCol;
}

void main() {
    vec2 uv = tc;
    
    float t = time_f * (0.2 + iFrequency * 0.2);
    float ampControl = clamp(iAmplitude, 0.0, 3.0);
    float strength = 0.8 + (ampControl * 0.5);
    
    vec2 center = vec2(0.5);
    if (iMouse.z > 0.0) {
        center = iMouse.xy / iResolution;
    }

    // Chromatic Aberration (RGB Split)
    // We offset the start position for each channel based on the ripple strength
    vec2 offset = vec2(0.005 * strength, 0.0);
    
    vec3 col;
    col.r = sampleHybrid(uv + offset, t, strength, center, iResolution).r;
    col.g = sampleHybrid(uv,          t, strength, center, iResolution).g;
    col.b = sampleHybrid(uv - offset, t, strength, center, iResolution).b;

    // Post Processing
    col = adjustContrast(col, iContrast);
    col = adjustSaturation(col, iSaturation);
    col = adjustBrightness(col, iBrightness);
    
    // Darken edges slightly
    float vig = 1.0 - length(uv - 0.5);
    col *= smoothstep(0.0, 1.2, vig);

    color = vec4(col, 1.0);
}