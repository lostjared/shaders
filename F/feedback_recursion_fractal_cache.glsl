#version 330 core
// infinite video feedback recursion through a multi-texture ring buffer.

in vec2 tc;
out vec4 color;

// --- Base Inputs ---
uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

// --- Ring Buffer Inputs ---
uniform sampler2D samp1;
uniform sampler2D samp2;
uniform sampler2D samp3;
uniform sampler2D samp4;
uniform sampler2D samp5;
uniform sampler2D samp6;
uniform sampler2D samp7;
uniform sampler2D samp8;

vec3 neonRing(float t) {
    return 0.5 + 0.5 * cos(6.28318 * (t + vec3(0.0, 0.33, 0.67)));
}

vec4 sampleCache(int idx, vec2 uv) {
    if (idx == 0) return texture(samp1, uv);
    if (idx == 1) return texture(samp2, uv);
    if (idx == 2) return texture(samp3, uv);
    if (idx == 3) return texture(samp4, uv);
    if (idx == 4) return texture(samp5, uv);
    if (idx == 5) return texture(samp6, uv);
    if (idx == 6) return texture(samp7, uv);
    return texture(samp8, uv);
}

void main() {
    // ==========================================
    // 1. AUDIO & FRACTAL GENERATION (Current Frame)
    // ==========================================
    float bass   = texture(spectrum, 0.03).r;
    float mid    = texture(spectrum, 0.22).r;
    float hiMid  = texture(spectrum, 0.40).r;
    float treble = texture(spectrum, 0.58).r;
    float air    = texture(spectrum, 0.80).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * 2.0;
    uv.x *= aspect;

    // Deep zoom with bass pulsation
    float fracZoom = pow(0.5, mod(iTime * 0.4, 9.0)) * (1.0 + bass * 0.4);
    vec2 p = uv * fracZoom;

    // Escape-time fractal
    float iters = 0.0;
    const float maxIters = 50.0;
    vec2 c = vec2(0.8 + mid * 0.2, 0.5 + 0.1 * sin(iTime * 0.25));
    for (float i = 0.0; i < maxIters; i++) {
        p = abs(p) / dot(p, p) - c;
        if (length(p) > 20.0) break;
        iters++;
    }
    float norm = iters / maxIters;

    // Distorted texture lookup through fractal field
    vec2 sampUV = tc + p * 0.02;
    sampUV = abs(fract(sampUV * 0.5 + 0.5) * 2.0 - 1.0);

    // Sample with mid-driven chromatic bloom
    float chroma = (mid + treble) * 0.035;
    vec3 baseCol;
    baseCol.r = texture(samp, sampUV + vec2(chroma, 0.0)).r;
    baseCol.g = texture(samp, sampUV).g;
    baseCol.b = texture(samp, sampUV - vec2(chroma, 0.0)).b;

    // Neon bloom rings based on iteration depth
    vec3 bloomAccum = vec3(0.0);
    for (float i = 0.0; i < 5.0; i++) {
        float ringDist = abs(norm - (i + 1.0) * 0.15);
        float ring = pow(0.01 / max(ringDist, 0.001), 0.8);
        float freq = texture(spectrum, (i + 1.0) * 0.08).r;
        bloomAccum += neonRing(i * 0.2 + iTime * 0.15 + freq) * ring * 0.12;
    }
    baseCol += bloomAccum;

    // Mid-driven glow halo around deep regions
    float depthGlow = smoothstep(0.3, 0.8, norm) * mid * 1.5;
    vec3 haloCol = neonRing(norm + iTime * 0.2 + bass);
    baseCol += haloCol * depthGlow * 0.25;

    // Fractal color from iteration
    vec3 fracCol;
    fracCol.r = norm * 1.5;
    fracCol.g = sin(iters * 0.4 + iTime);
    fracCol.b = length(p) * 0.08;
    baseCol = mix(baseCol, baseCol * (fracCol + 0.5), 0.25 + hiMid * 0.2);

    baseCol *= 0.85 + amp_smooth * 0.35;
    baseCol *= 1.0 + bass * 0.3;
    baseCol = mix(baseCol, vec3(1.0) - baseCol, smoothstep(0.93, 1.0, amp_peak));


    // ==========================================
    // 2. RING BUFFER FEEDBACK RECURSION
    // ==========================================
    // Unified time variable (using iTime instead of time_f)
    float fbZoomPerLayer = 0.96 + 0.02 * sin(iTime * 0.5);
    float fbRotPerLayer = 0.03 * sin(iTime * 0.3);

    // Offset center drifts slowly
    vec2 feedbackCenter = vec2(
        0.5 + 0.02 * sin(iTime * 0.4),
        0.5 + 0.02 * cos(iTime * 0.35)
    );

    vec3 accum = baseCol;
    float accWeight = 1.0;

    for (int i = 0; i < 8; i++) {
        float gen = float(i + 1);

        // Compound the transform
        float fbZoomGen = pow(fbZoomPerLayer, gen);
        float rot = fbRotPerLayer * gen;
        float cs = cos(rot), sn = sin(rot);

        vec2 centered = tc - feedbackCenter;
        centered *= fbZoomGen;
        centered = vec2(centered.x * cs - centered.y * sn,
                        centered.x * sn + centered.y * cs);
        vec2 fbUV = centered + feedbackCenter;

        // GLITCH INJECTION: Warp the history buffer coordinates using the current frame's
        // escape-time vector (p). This makes the feedback trails tear and smear in 
        // response to the audio-driven fractal geometry.
        fbUV += p * 0.0015 * gen; 

        vec4 cached = sampleCache(i, fbUV);

        // Feedback color shift
        float shift = gen * 0.02;
        cached.r *= 1.0 + shift;
        cached.g *= 1.0 - shift * 0.5;
        cached.b *= 1.0 + shift * 0.3;

        // Decay weight
        float w = pow(0.7, gen);
        accum += cached.rgb * w;
        accWeight += w;
    }

    accum /= accWeight;

    // Contrast boost
    accum = (accum - 0.5) * 1.15 + 0.5;
    accum = clamp(accum, 0.0, 1.0);

    color = vec4(accum, 1.0);
}