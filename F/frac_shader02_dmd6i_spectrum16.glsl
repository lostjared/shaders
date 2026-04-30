#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform vec2 iResolution;
uniform float time_f;
uniform vec4 iMouse;
uniform sampler1D spectrum; // live FFT (always bound when audio is enabled)

// Audio variables
uniform float amp_peak;
uniform float amp_rms;
uniform float amp_smooth;
uniform float amp_low;
uniform float amp_mid;
uniform float amp_high;

// 16 Temporal Buffers
uniform sampler1D spectrum0;  // T=0 (Now)
uniform sampler1D spectrum1;
uniform sampler1D spectrum2;
uniform sampler1D spectrum3;
uniform sampler1D spectrum4;
uniform sampler1D spectrum5;
uniform sampler1D spectrum6;
uniform sampler1D spectrum7;
uniform sampler1D spectrum8;
uniform sampler1D spectrum9;
uniform sampler1D spectrum10;
uniform sampler1D spectrum11;
uniform sampler1D spectrum12;
uniform sampler1D spectrum13;
uniform sampler1D spectrum14;
uniform sampler1D spectrum15; // T=15 (Oldest)

const float PI = 3.14159265358979323846;

// Helper to sample the 16-stack
float sample16(int index, float freq) {
    switch(index) {
        case 0: return texture(spectrum0, freq).r;
        case 1: return texture(spectrum1, freq).r;
        case 2: return texture(spectrum2, freq).r;
        case 3: return texture(spectrum3, freq).r;
        case 4: return texture(spectrum4, freq).r;
        case 5: return texture(spectrum5, freq).r;
        case 6: return texture(spectrum6, freq).r;
        case 7: return texture(spectrum7, freq).r;
        case 8: return texture(spectrum8, freq).r;
        case 9: return texture(spectrum9, freq).r;
        case 10: return texture(spectrum10, freq).r;
        case 11: return texture(spectrum11, freq).r;
        case 12: return texture(spectrum12, freq).r;
        case 13: return texture(spectrum13, freq).r;
        case 14: return texture(spectrum14, freq).r;
        default: return texture(spectrum15, freq).r;
    }
}

float pingPong(float x, float length) {
    float m = mod(x, length * 2.0);
    return m <= length ? m : length * 2.0 - m;
}

vec2 rotateUV(vec2 uv, float angle, vec2 c, float aspect) {
    float s = sin(angle), cc = cos(angle);
    vec2 p = uv - c;
    p.x *= aspect;
    p = mat2(cc, -s, s, cc) * p;
    p.x /= aspect;
    return p + c;
}

vec2 reflectUV(vec2 uv, float segments, vec2 c, float aspect) {
    vec2 p = uv - c;
    p.x *= aspect;
    float ang = atan(p.y, p.x);
    float rad = length(p);
    float stepA = 6.2831853 / segments;
    ang = mod(ang, stepA);
    ang = abs(ang - stepA * 0.5);
    vec2 r = vec2(cos(ang), sin(ang)) * rad;
    r.x /= aspect;
    return r + c;
}

// FRACTAL FOLD: Each iteration uses a different history buffer.
// `histPhase` is the smooth, monotonically advancing audio-driven offset
// (continuous across frames; never wraps), so the fold motion never snaps.
vec2 fractalFold(vec2 uv, float zoom, float t, float histPhase, vec2 c, float aspect) {
    vec2 p = uv;
    for (int i = 0; i < 6; i++) {
        // Use history buffers 0-5 for the 6 iterations
        float fft = sample16(i, 0.5);
        // Phase is histPhase + per-iteration offset; *no* (zoom + fft*..) sin-of-time
        // multiplier (that caused phase jumps when fft changed). fft now only
        // adds a small continuous bias to the per-iteration phase.
        float phase = histPhase * (0.35 + 0.05 * float(i)) + float(i) * 0.7;
        float z = zoom + 0.15 * sin(phase) + fft * 0.10;
        p = abs((p - c) * z) - 0.5 + c;
        p = rotateUV(p, histPhase * 0.12 + float(i) * 0.07 + fft * 0.05, c, aspect);
    }
    return p;
}

vec3 neonPalette(float t) {
    vec3 pink = vec3(1.0, 0.15, 0.75);
    vec3 blue = vec3(0.10, 0.55, 1.0);
    vec3 green = vec3(0.10, 1.00, 0.45);
    float ph = fract(t * 0.08);
    vec3 k1 = mix(pink, blue, smoothstep(0.00, 0.33, ph));
    vec3 k2 = mix(blue, green, smoothstep(0.33, 0.66, ph));
    vec3 k3 = mix(green, pink, smoothstep(0.66, 1.00, ph));
    return normalize(mix(mix(k1, k2, step(0.33, ph)), k3, step(0.66, ph))) * 1.05;
}

float hash1(float n) {
    return fract(sin(n * 127.1 + 311.7) * 43758.5453123);
}

vec2 diamondFold(vec2 uv, vec2 c, float aspect) {
    vec2 p = (uv - c) * vec2(aspect, 1.0);
    p = abs(p);
    if (p.y > p.x) p = p.yx;
    p.x /= aspect;
    return p + c;
}

// Map unbounded warped coordinates to [0,1] continuously (no periodic wrap).
// This avoids the visible "jump back" from fract() when the zoom crosses an
// integer boundary in texture space.
vec2 continuousUv(vec2 pwrap, vec2 ar, vec2 center) {
    vec2 n = pwrap / ar;
    vec2 bounded = n / (1.0 + abs(n)); // (-inf, inf) -> (-1, 1)
    vec2 uv = center + 0.5 * bounded;
    return clamp(uv, vec2(0.001), vec2(0.999));
}

void main(void) {
    vec4 baseTex = texture(samp, tc);
    vec2 uv = tc * 2.0 - 1.0;
    float aspect = iResolution.x / iResolution.y;
    vec2 ar = vec2(aspect, 1.0);
    vec2 m = (iMouse.z > 0.5) ? (iMouse.xy / iResolution) : vec2(0.5);

    // 1. Radial Audio Sampling (Temporal Echo)
    float distFromCenter = length((tc - m) * ar);
    float historySelect = clamp(distFromCenter * 15.0, 0.0, 15.0);
    int hIdx = int(historySelect);
    float hFrac = fract(historySelect);

    // Smoothly blend between 16 buffers based on radius
    float fftCurrent = sample16(hIdx, clamp(distFromCenter * 0.5, 0.0, 1.0));
    float fftNext = sample16(min(hIdx + 1, 15), clamp(distFromCenter * 0.5, 0.0, 1.0));
    float fft = mix(fftCurrent, fftNext, hFrac);

    // Live FFT fallback channel (for cases where history buffers are not
    // configured/populated even though the shader declares spectrum0..15).
    float liveFft = texture(spectrum, clamp(distFromCenter * 0.5, 0.0, 1.0)).r;

    // ------------------------------------------------------------------
    // SMOOTH AUDIO-DRIVEN PHASE.
    // We sum a broadband sample from every shell to get total energy stored
    // across the 16-frame ring buffer. This sum is continuous frame-to-frame
    // (each shell shifts down one slot per frame), so multiplying it into a
    // motion phase produces fluid drift that never snaps when audio changes.
    // It plays the role of an integrator without needing shader state.
    float spectrumSum = 0.0;
    for (int i = 0; i < 16; i++) {
        spectrumSum += sample16(i, 0.25) + sample16(i, 0.75);
    }
    spectrumSum *= 0.03125; // 1/(16*2)

    // Detect whether history is actually evolving. If all spectrumN are nearly
    // identical/flat, use live FFT + amp bands to avoid fixed time-loop motion.
    float histDelta = 0.0;
    for (int i = 0; i < 15; i++) {
        histDelta += abs(sample16(i, 0.25) - sample16(i + 1, 0.25));
    }
    histDelta *= (1.0 / 15.0);
    float historyValid = smoothstep(0.002, 0.02, histDelta + spectrumSum * 0.2);

    // historyEnergy = energy of the LOCAL shell only (drives this pixel)
    float histEnergy = 0.0;
    histEnergy += sample16(hIdx, 0.10);
    histEnergy += sample16(hIdx, 0.40);
    histEnergy += sample16(hIdx, 0.80);
    histEnergy *= 0.333;

    // Blend local history with live FFT so movement remains audio-driven even
    // when history buffers are unavailable or only partially configured.
    float audioEnergy = mix(liveFft, histEnergy, historyValid);
    audioEnergy = max(audioEnergy, 0.35 * (amp_low + amp_mid + amp_high));

    // CRITICAL: phase MUST be a function of time_f *alone* so it accumulates
    // monotonically. Audio is only allowed to ADD a bounded offset (size O(1)),
    // never to SCALE time_f - that would multiply Δrate by all of t and
    // produce huge phase jumps after the first minute.
    float basePhase  = time_f * 0.6;
    float audioOffset = mix(liveFft, spectrumSum, historyValid) * 1.2; // bounded
    float audioPhase = basePhase + audioOffset;     // ALWAYS continuous

    // Monotonic evolving hash driver: non-repeating evolution over time.
    float evo = audioPhase * (0.22 + audioEnergy * 0.6) + spectrumSum * 3.7;
    float evoIdx = floor(evo);
    float evoFrac = fract(evo);
    float evoHash = mix(hash1(evoIdx + 5.0), hash1(evoIdx + 6.0), evoFrac);
    // ------------------------------------------------------------------

    // 2. Modified Kaleidoscope Reflection.
    // Use the smooth audio phase instead of raw time_f, and use historyEnergy
    // (continuous, per-shell) instead of the radius-blended fft so segments
    // don't visibly snap when fft changes per frame.
    float seg = 4.0 + (2.0 + audioEnergy * 4.0) * (0.35 + 0.65 * evoHash);
    vec2 kUV = reflectUV(tc, seg, m, aspect);
    kUV = diamondFold(kUV, m, aspect);

    // 3. Fractal Folding driven by smooth audioPhase (no time_f-vs-fft jumps).
    float foldZoom = 1.25 + 0.9 * audioEnergy + 0.35 * (evoHash - 0.5);
    kUV = fractalFold(kUV, foldZoom, time_f, audioPhase, m, aspect);
    kUV = rotateUV(kUV, audioPhase * (0.18 + audioEnergy * 0.45), m, aspect);
    kUV = diamondFold(kUV, m, aspect);

    // 4. Continuous Audio Drift Warp (non-periodic, no orbital wrap).
    vec2 p = (kUV - m) * ar;
    float rD = max(length(p), 1e-6);

    // Monotonic drift from audio/history. This is linear in time and audio
    // energy; no angle wrap terms (atan/cos/sin orbit) so no fixed cycle point.
    float drift = audioPhase * (0.22 + audioEnergy * 0.65 + spectrumSum * 0.15);

    // Long-evolving pseudo-random bias from drift index, blended continuously.
    float dIdx = floor(drift * 0.07);
    float dFrac = fract(drift * 0.07);
    vec2 dA = vec2(hash1(dIdx + 19.0), hash1(dIdx + 43.0)) - 0.5;
    vec2 dB = vec2(hash1(dIdx + 20.0), hash1(dIdx + 44.0)) - 0.5;
    vec2 driftBias = mix(dA, dB, dFrac) * (0.35 + audioEnergy * 0.45);

    // Non-periodic radial terms (log/sqrt/polynomial), audio-reactive.
    float radialGain = 1.2 + audioEnergy * 3.0 + spectrumSum * 1.1;
    float logTerm = log(1.0 + rD * radialGain);
    float sqrtTerm = sqrt(rD) * (0.35 + audioEnergy * 0.4);
    float polyTerm = rD * rD * (0.03 + 0.08 * evoHash);

    // Affine + drift warp: no circular phase reset because there is no periodic
    // angular parameter in the main transport path.
    vec2 pwrap;
    pwrap.x = p.x * (1.0 + 0.55 * audioEnergy) + logTerm + drift * 0.11 + driftBias.x;
    pwrap.y = p.y * (1.0 + 0.40 * audioEnergy) + sqrtTerm + drift * 0.073 + polyTerm + driftBias.y;

    // Chromatic Split using the temporal shift
    float chromaShift = (0.0015 + audioEnergy * 0.005) * mix(0.5, 2.0, amp_high);

    vec2 off = normalize(pwrap + 1e-6) * chromaShift;
    vec2 u0 = continuousUv(pwrap, ar, m);

    vec3 finalRGB;
    finalRGB.r = texture(samp, u0 + off).r;
    finalRGB.g = texture(samp, u0).g;
    finalRGB.b = texture(samp, u0 - off).b;
    // ------------------------------------------------------------------------

    // 5. Final Glow & Vignette
    float pulse = 0.5 + 0.5 * clamp(
        log(1.0 + abs(drift) * 0.08 + rD * (5.0 + audioEnergy * 6.0)) * 0.33
        + evoHash * 0.55,
        0.0,
        1.0
    );
    finalRGB *= (0.85 + 0.15 * pulse);

    float vign = 1.0 - smoothstep(0.5, 1.5, distFromCenter);
    finalRGB *= (vign + audioEnergy * 0.3);

    // Audio-driven Final Color Grading
    finalRGB *= 1.0 + audioEnergy * 0.8;
    finalRGB = mix(finalRGB, finalRGB.zyx, audioEnergy * 0.4);

    color = vec4(clamp(finalRGB, 0.0, 1.0), baseTex.a);
}