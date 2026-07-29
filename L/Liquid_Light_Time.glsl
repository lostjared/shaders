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

// --- UTILITY FUNCTIONS ---

float pingPong(float x, float length) {
    float modVal = mod(x, length * 2.0);
    return modVal <= length ? modVal : length * 2.0 - modVal;
}

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

// --- NEON PALETTE ---
vec3 getNeonPalette(float t) {
    float x = fract(t); 
    vec3 colBlue   = vec3(0.05, 0.2, 1.0);
    vec3 colPurple = vec3(0.7, 0.0, 1.0);
    vec3 colPink   = vec3(1.0, 0.05, 0.5);
    
    if (x < 0.33) return mix(colBlue, colPurple, x * 3.0);
    else if (x < 0.66) return mix(colPurple, colPink, (x - 0.33) * 3.0);
    else return mix(colPink, colBlue, (x - 0.66) * 3.0);
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
    vec2 deriv = fwidth(tc);
    if (deriv.x > 0.0 || deriv.y > 0.0) {
        lod = log2(max(max(deriv.x, deriv.y) * max(ts.x, ts.y), 1.0));
    }
    return textureLod(tex, sampleUV, lod);
}

vec2 rotate2D(vec2 p, float a) {
    float c = cos(a); float s = sin(a);
    return mat2(c, -s, s, c) * p;
}

// --- FRACTAL & GEOMETRY ---

vec2 kaleido(vec2 p, float slices) {
    float pi = 3.14159265359;
    float r = length(p);
    float a = atan(p.y, p.x);
    float sector = pi * 2.0 / slices;
    a = mod(a, sector);
    a = abs(a - sector * 0.5);
    return vec2(cos(a), sin(a)) * r;
}

// --- NOISE ---
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
               mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    mat2 rot = mat2(cos(0.5), sin(0.5), -sin(0.5), cos(0.5));
    for (int i = 0; i < 4; i++) { 
        v += a * noise(p);
        p = rot * p * 2.0 + vec2(100.0);
        a *= 0.5;
    }
    return v;
}

// --- COMBINED RENDER LOGIC ---

vec3 sampleSuperShader(vec2 uv, float t, vec2 center, vec2 res) {
    float aspect = res.x / res.y;
    vec2 p = (uv - center) * vec2(aspect, 1.0);
    
    // 1. Zoom & Rotation
    p = rotate2D(p, iRotation);
    float zoom = max(iZoom, 0.01);
    p /= zoom;
    
    // 2. PingPong Wave (Rhythmic Breathing)
    // Replaced 'time_f' with 't' (accelerated time)
    float time_t = pingPong(t, 10.0) + 1.0;
    float time_s = pingPong(t, 5.0);
    
    float waveFreq = 2.0 + iFrequency * 2.0;
    float waveAmp  = 0.1 * sin(0.2 * time_t) * iAmplitude;
    float waveSpd  = sin(0.3 * time_s);
    
    p.y += sin(p.x * waveFreq + t * waveSpd) * waveAmp;

    // 3. Fractal Geometry
    if (iFrequency > 0.2) {
        float slices = 4.0 + floor(iFrequency * 6.0);
        p = kaleido(p, slices);
        
        int iterations = 2 + int(iFrequency * 2.0);
        float scale = 1.1;
        float shift = 0.1;
        for(int i = 0; i < iterations; i++) {
            p = abs(p);
            p -= shift;
            p *= scale;
            p = rotate2D(p, t * 0.05 + float(i));
        }
    }

    // 4. Liquid Domain Warping
    vec2 q = vec2(0.0);
    q.x = fbm(p + vec2(0.0, 0.0) + 0.05*t);
    q.y = fbm(p + vec2(5.2, 1.3) + 0.05*t);

    vec2 r = vec2(0.0);
    r.x = fbm(p + 4.0*q + vec2(t * 0.1)); 
    r.y = fbm(p + 4.0*q + vec2(t * 0.05, 2.8));

    float liquidStrength = 0.2 + (iAmplitude * 0.5);
    vec2 distortion = r * liquidStrength;
    
    // 5. Texture Sampling (Warped)
    vec2 finalUV = uv + distortion;
    
    // Sync wave logic to the lookup
    finalUV.y += sin(finalUV.x * waveFreq + t * waveSpd) * waveAmp;
    
    vec3 texCol = mxTexture(samp, finalUV).rgb;
    
    // 6. Color Blending (Texture + Neon Overlay)
    float pattern = length(q) + length(r) + t * 0.1;
    vec3 neon = getNeonPalette(pattern);
    
    vec3 col = texCol;
    float turbulence = length(r);
    
    // Blend logic: Only add neon where the liquid is active
    // This preserves the original texture colors in calm spots
    vec3 rainbowOverlay = texCol * neon * 1.5; 
    col = mix(col, rainbowOverlay, turbulence * iSaturation * 0.8);
    
    // Specular shine
    col += neon * pow(turbulence, 3.0) * 0.5 * iAmplitude;

    return col;
}

void main() {
    vec2 uv = tc;
    uv = wrapUV(uv);
    
    // --- ACCELERATION LOGIC ---
    // t = Time + (Acceleration * Time^2)
    // 0.2  = Base Speed
    // 0.05 = Acceleration Rate (Increases speed significantly over time)
    float accelTime = (time_f * 0.2) + (time_f * time_f * 0.05);
    
    vec2 center = vec2(0.5);
    if (iMouse.z > 0.0) {
        center = iMouse.xy / iResolution;
    }

    // Chromatic Aberration
    float caStrength = 0.003 * (1.0 + iAmplitude);
    
    vec3 col;
    col.r = sampleSuperShader(uv + vec2(caStrength, 0.0), accelTime, center, iResolution).r;
    col.g = sampleSuperShader(uv,                         accelTime, center, iResolution).g;
    col.b = sampleSuperShader(uv - vec2(caStrength, 0.0), accelTime, center, iResolution).b;

    // Post Processing
    col = adjustBrightness(col, iBrightness);
    col = adjustContrast(col, iContrast);
    col = adjustSaturation(col, iSaturation);
    col = rotateHue(col, iHueShift);
    
    // Vignette
    vec2 vUV = uv * (1.0 - uv.yx); 
    float vig = vUV.x * vUV.y * 15.0; 
    vig = pow(vig, 0.2); 
    col *= vig;

    color = vec4(col, 1.0);
}