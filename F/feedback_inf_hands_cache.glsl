#version 330 core
// Infinite Kaleidoscope Base + Deep Recursive History Tunnel

in vec2 tc;
out vec4 color;

// --- Base Inputs ---
uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;
uniform float time_speed;
uniform float time_f;
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
    if (idx == 0)
        return texture(samp1, uv);
    if (idx == 1)
        return texture(samp2, uv);
    if (idx == 2)
        return texture(samp3, uv);
    if (idx == 3)
        return texture(samp4, uv);
    if (idx == 4)
        return texture(samp5, uv);
    if (idx == 5)
        return texture(samp6, uv);
    if (idx == 6)
        return texture(samp7, uv);
    return texture(samp8, uv);
}

void main() {
    // ==========================================
    // 1. AUDIO SENSING
    // ==========================================
    float bass = texture(spectrum, 0.03).r;
    float mid = texture(spectrum, 0.22).r;
    float hiMid = texture(spectrum, 0.40).r;
    float treble = texture(spectrum, 0.58).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * 2.0;
    uv.x *= aspect;

    // ==========================================
    // 2. KALEIDOSCOPE FOLDING (Base Video Layer)
    // ==========================================
    float angle = atan(uv.y, uv.x);

    // Knob physically rotates the base video up to 180 degrees
    angle += mix(0.0, 3.14159, time_speed);

    float radius = length(uv);
    float segments = 6.0;
    angle = mod(angle, 6.28318 / segments);
    angle = abs(angle - 3.14159 / segments);

    // Reconstruct the UV coordinates from the folded polar math
    vec2 kalUV = vec2(cos(angle), sin(angle)) * radius;

    // Map back to 0.0 - 1.0 texture space
    vec2 baseUV = kalUV * 0.5 + 0.5;
    baseUV.x /= aspect; // Correct aspect stretch

    // Sample the base video with chromatic split
    float chroma = (mid + treble) * 0.02;
    vec3 baseCol;
    baseCol.r = texture(samp, baseUV + vec2(chroma, 0.0)).r;
    baseCol.g = texture(samp, baseUV).g;
    baseCol.b = texture(samp, baseUV - vec2(chroma, 0.0)).b;

    // Audio flash / inversion
    baseCol *= 0.85 + amp_smooth * 0.35;
    baseCol *= 1.0 + bass * 0.3;
    baseCol = mix(baseCol, vec3(1.0) - baseCol, smoothstep(0.93, 1.0, amp_peak));

    // ==========================================
    // 3. RING BUFFER FEEDBACK RECURSION
    // ==========================================
    // FIX 1: Zoom multiplier > 1.0 forces coordinates outward, making the rendered
    // history frames smaller on screen. This creates the deep receding tunnel.
    float baseZoom = mix(1.0, 1.15, time_f);
    // ==========================================
    // 3. RING BUFFER FEEDBACK RECURSION (Sub-Frame Blending)
    // ==========================================
    float fbZoomPerLayer = 1.0;

    // We can push the rotation higher now because we are faking 15 frames
    float fbRotPerLayer = mix(0.0, 0.08, time_f);

    vec2 feedbackCenter = vec2(
        0.5 + 0.015 * sin(iTime * 0.4),
        0.5 + 0.015 * cos(iTime * 0.35));

    vec3 accum = baseCol;
    float accWeight = 1.0;

    // Loop through 7 times, but take TWO samples per loop (14 history taps total)
    for (int i = 0; i < 7; i++) {
        // Step A (The actual frame)
        float genA = float(i + 1);
        float rotA = fbRotPerLayer * genA;
        float csA = cos(rotA), snA = sin(rotA);
        vec2 centerA = tc - feedbackCenter;
        vec2 uvA = vec2(centerA.x * csA - centerA.y * snA, centerA.x * snA + centerA.y * csA) + feedbackCenter;

        // Step B (The "Phantom" frame floating exactly halfway between this frame and the next)
        float genB = float(i) + 1.5;
        float rotB = fbRotPerLayer * genB;
        float csB = cos(rotB), snB = sin(rotB);
        vec2 centerB = tc - feedbackCenter;
        vec2 uvB = vec2(centerB.x * csB - centerB.y * snB, centerB.x * snB + centerB.y * csB) + feedbackCenter;

        // Sample the hardware cache for both the real frame and the phantom position
        vec4 cachedA = sampleCache(i, uvA);
        vec4 cachedB = mix(sampleCache(i, uvB), sampleCache(i + 1, uvB), 0.5);

        // Apply depth color shifts
        float shiftA = genA * 0.035;
        cachedA.rgb *= vec3(1.0 + shiftA, 1.0 - shiftA * 0.5, 1.0 + shiftA * 0.8);

        float shiftB = genB * 0.035;
        cachedB.rgb *= vec3(1.0 + shiftB, 1.0 - shiftB * 0.5, 1.0 + shiftB * 0.8);

        // Calculate decay weights
        float wA = pow(0.75, genA);
        float wB = pow(0.75, genB);

        // Accumulate both
        accum += cachedA.rgb * wA;
        accum += cachedB.rgb * wB;
        accWeight += (wA + wB);
    }

    accum /= accWeight;

    // Contrast boost
    accum = (accum - 0.5) * 1.2 + 0.5;
    accum = clamp(accum, 0.0, 1.0);

    color = vec4(accum, 1.0);
}