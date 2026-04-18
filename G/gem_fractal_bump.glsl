#version 330 core

in vec2 tc;
out vec4 color;

// ACMX2 Standard Uniforms
uniform float time_f;
uniform float time_speed;
uniform sampler2D samp;
uniform vec2 iResolution;
uniform vec4 iMouse;
uniform float amp;
uniform float uamp;
uniform float iTime;
uniform int iFrame;
uniform float iTimeDelta;
uniform vec4 iDate;
uniform vec2 iMouseClick;
uniform float iFrameRate;
uniform vec3 iChannelResolution[4];
uniform float iChannelTime[4];
uniform float iSampleRate;
uniform float amp_peak;
uniform float amp_rms;
uniform float amp_smooth;
uniform float amp_low;
uniform float amp_mid;
uniform float amp_high;
uniform float iamp;

// The New Hotness
uniform sampler1D spectrum; // Bound to unit 9

const float PI  = 3.1415926535897932384626433832795;
const float TAU = 6.28318530718;

// --- utility ---

float pingPong(float x, float len) {
    float m = mod(x, len * 2.0);
    return m <= len ? m : len * 2.0 - m;
}

// Spectrum-based Gradient: Converts frequency intensity to a Neon Glow
vec3 spectrumGradient(float t, float intensity) {
    vec3 col1 = vec3(0.1, 0.8, 1.0); // Cyan
    vec3 col2 = vec3(1.0, 0.1, 0.6); // Hot Pink
    vec3 col3 = vec3(0.5, 0.1, 1.0); // Purple
    
    float p = fract(t + intensity);
    vec3 grad = mix(col1, col2, smoothstep(0.0, 0.5, p));
    grad = mix(grad, col3, smoothstep(0.5, 1.0, p));
    
    return grad * (0.5 + intensity * 2.0);
}

vec2 rotateUV(vec2 uv, float angle, vec2 ctr, float aspect) {
    float s = sin(angle), cc = cos(angle);
    vec2 p = uv - ctr;
    p.x *= aspect;
    p = mat2(cc, -s, s, cc) * p;
    p.x /= aspect;
    return p + ctr;
}

vec2 reflectUV(vec2 uv, float segments, vec2 ctr, float aspect) {
    vec2 p = uv - ctr;
    p.x *= aspect;
    float ang = atan(p.y, p.x);
    float rad = length(p);
    float step_ = TAU / segments;
    ang = mod(ang, step_);
    ang = abs(ang - step_ * 0.5);
    vec2 r = vec2(cos(ang), sin(ang)) * rad;
    r.x /= aspect;
    return r + ctr;
}

vec2 diamondFold(vec2 uv, vec2 ctr, float aspect) {
    vec2 p = (uv - ctr) * vec2(aspect, 1.0);
    p = abs(p);
    if (p.y > p.x) p = p.yx;
    p.x /= aspect;
    return p + ctr;
}

// --- recursive fractal fold (Driven by Spectrum) ---
vec2 fractalFold(vec2 uv, float zoom, float t, vec2 ctr, float aspect, int iters, float bassEnergy) {
    vec2 p = uv;
    for (int i = 0; i < iters; i++) {
        // Bass bumps the zoom factor
        float bumpZoom = zoom + (bassEnergy * 0.4);
        p = abs((p - ctr) * (bumpZoom + 0.15 * sin(t * (0.35 + bassEnergy * 0.2) + float(i)))) - 0.5 + ctr;
        p = rotateUV(p, t * 0.12 + float(i) * 0.07, ctr, aspect);
    }
    return p;
}

void main(void) {
    float aspect = iResolution.x / iResolution.y;
    vec2  ar     = vec2(aspect, 1.0);

    // --- Direct Spectrum Sampling ---
    float sBass   = texture(spectrum, 0.02).r; // Precise deep sub-kick
    float sMid    = texture(spectrum, 0.20).r; // Harmonic mids
    float sTreble = texture(spectrum, 0.60).r; // Sharp treble
    
    float t = time_f;
    float tSlow = t * 0.5;

    vec2 ctr = (iMouse.z > 0.5)
             ? iMouse.xy / iResolution
             : vec2(0.5 + 0.1 * sin(tSlow * 0.5), 0.5 + 0.1 * cos(tSlow * 0.4));

    // --- The "Bump" Logic ---
    // Segments and Zoom now react specifically to the bass bin
    float seg  = 4.0 + (sBass * 8.0); 
    float zoom = 1.2 + (sBass * 1.5);
    int foldIters = 5 + int(sMid * 5.0); 

    vec2 kUV = reflectUV(tc, seg, ctr, aspect);
    kUV = diamondFold(kUV, ctr, aspect);
    kUV = fractalFold(kUV, zoom, t, ctr, aspect, foldIters, sBass);

    // --- Log-Polar Spiral Warp (Reacts to Peaks) ---
    vec2  p  = (kUV - ctr) * ar;
    float rD = length(p) + 1e-6;
    float ang = atan(p.y, p.x);

    // Spiral twist tightens with treble peaks
    ang += (0.5 + sTreble * 2.0) * sin(rD * 10.0 + t);
    
    vec2 pwrap = vec2(cos(ang), sin(ang)) * exp(fract(log(rD) - t * 0.5));
    vec2 logUV = fract(pwrap / ar + ctr);

    // --- Chromatic Aberration (Spectrum Driven) ---
    float chromaStr = 0.005 + sTreble * 0.05;
    vec3 fracCol;
    fracCol.r = texture(samp, logUV + vec2(chromaStr, 0.0)).r;
    fracCol.g = texture(samp, logUV).g;
    fracCol.b = texture(samp, logUV - vec2(chromaStr, 0.0)).b;

    // --- Spectrum Gradient Overlay ---
    // This creates the "Bumping" colors by mapping intensity to Hue
    vec3 grad = spectrumGradient(tSlow, sMid);
    fracCol = mix(fracCol, grad * fracCol * 2.5, 0.4 + sBass * 0.3);

    // --- Bloom and Contrast ---
    fracCol += pow(max(fracCol - 0.5, 0.0), vec3(2.0)) * 0.5;
    
    // Final Output: Pulse brightness with the kick
    fracCol *= (0.8 + sBass * 1.5);
    
    color = vec4(fracCol, 1.0);
}