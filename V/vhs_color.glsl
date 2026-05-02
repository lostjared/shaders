#version 330 core

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

// NTSC-inspired color constants
const vec3 VHS_RED = vec3(0.7, 0.1, 0.2);
const vec3 VHS_GREEN = vec3(0.0, 0.6, 0.4);
const vec3 VHS_BLUE = vec3(0.1, 0.2, 0.6);

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

void main() {
    // 1. Audio Sampling
    float bass = texture(spectrum, 0.05).r;
    float mid = texture(spectrum, 0.30).r;
    float treble = texture(spectrum, 0.70).r;

    // 2. Analog Tape Jitter
    vec2 uv = tc;

    // Tracking error: horizontal shift that "tears" at the top or bottom
    float tear = step(0.9, sin(uv.y * 2.0 + time_f)) * sin(uv.y * 20.0) * 0.02 * bass;
    uv.x += tear + (hash(vec2(time_f)) - 0.5) * 0.005 * treble;

    // 3. Recursive Signal Folding (The "Feedback Loop")
    vec2 p = uv - 0.5;
    p.x *= iResolution.x / iResolution.y;

    vec3 signal = vec3(0.0);
    float iterations = 5.0;

    for (float i = 0.0; i < iterations; i++) {
        // Rotate and scale the coordinate space recursively
        p *= rot(time_f * 0.1 + i * 0.2 + mid * 0.5);
        p = abs(p) - 0.1 - (bass * 0.05);

        // Sample the main texture with shifting UVs
        vec2 feedbackUV = p + 0.5;
        float chromaShift = 0.02 * (i / iterations) + (treble * 0.05);

        signal.r += texture(samp, feedbackUV + vec2(chromaShift, 0.0)).r;
        signal.g += texture(samp, feedbackUV).g;
        signal.b += texture(samp, feedbackUV - vec2(chromaShift, 0.0)).b;
    }
    signal /= iterations;

    // 4. VHS Color Palette Mapping
    // We map the signal intensity to a faded, magnetic color ramp
    vec3 vhsPalette = mix(VHS_BLUE, VHS_RED, uv.y + mid);
    vhsPalette = mix(vhsPalette, VHS_GREEN, sin(time_f + p.x) * 0.5 + 0.5);

    vec3 col = signal * vhsPalette;

    // 5. Artifacts & Post-Processing
    // Acutance (Sharpening/Ghosting)
    col += (signal - 0.5) * 0.3;

    // Static/Snow (increases with amplitude)
    float snow = hash(uv + time_f) * 0.15 * (1.0 + amp_smooth);
    col += snow;

    // Scanlines (Moving slightly to simulate CRT refresh)
    float scanline = sin(uv.y * iResolution.y * 0.8 + time_f * 10.0) * 0.04;
    col -= scanline;

    // Magnetic "Edge Bleed" (Fading edges to black/blue)
    float vignette = smoothstep(0.8, 0.2, length(uv - 0.5));
    col *= vignette + 0.2;

    // 6. Signal Clipping & Inversion
    col = clamp(col, 0.02, 0.95); // Prevent pure black/white for analog feel

    if (amp_peak > 0.98) {
        col = vec3(1.0) - col; // Hard signal clip/inversion on peaks
    }

    // Final Gain
    col *= 0.9 + amp_smooth * 0.3;

    color = vec4(col, 1.0);
}