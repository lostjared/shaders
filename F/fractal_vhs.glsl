#version 330 core

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float TAU = 6.28318530718;

mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

vec3 crystal(float t) {
    return 0.5 + 0.5 * cos(TAU * (t + vec3(0.0, 0.1, 0.2)));
}

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void main() {
    float bass = texture(spectrum, 0.03).r;
    float mid = texture(spectrum, 0.22).r;
    float treble = texture(spectrum, 0.58).r;

    // --- VHS JITTER & DISTORTION ---
    vec2 uv = tc;

    // Horizontal "tape" wiggle
    float wiggle = sin(uv.y * 10.0 + time_f * 5.0) * 0.002;
    // Periodic tracking glitch based on bass
    float tracking = step(0.98, hash(vec2(time_f * 0.1, 0.0))) * sin(uv.y * 100.0) * 0.01;
    uv.x += wiggle + (tracking * bass);

    vec2 p = (uv - 0.5) * vec2(iResolution.x / iResolution.y, 1.0);
    p *= (1.1 + bass * 0.2);

    // --- RECURSIVE FRACTAL ENGINE ---
    float scale = 1.0;
    float iter_sum = 0.0;
    const int iterations = 6;
    for (int i = 0; i < iterations; i++) {
        p = abs(p) - 0.5 - (mid * 0.05);
        p *= rot(time_f * 0.15 + float(i) * 0.4);
        float s = 1.6 + bass * 0.1;
        p *= s;
        scale *= s;
        iter_sum += exp(-length(p) * 0.5);
    }

    // --- TEXTURE SAMPLING (VHS COLOR FRINGING) ---
    vec2 sampUV = (p / scale) + 0.5;

    // Increased Chromatic Aberration for VHS look
    float shift = 0.01 + (treble * 0.03);
    vec3 col;
    col.r = texture(samp, sampUV + vec2(shift, 0.0)).r;
    col.g = texture(samp, sampUV).g;
    col.b = texture(samp, sampUV - vec2(shift, 0.0)).b;

    // --- COLOR COMPOSITION ---
    vec3 fractalCol = crystal(iter_sum * 0.1 + time_f * 0.2);
    col = mix(col, fractalCol, clamp(iter_sum / float(iterations), 0.0, 1.0));
    col += crystal(time_f) * (iter_sum * 0.2) * mid;

    // --- VHS POST-PROCESSING ---
    // 1. Scanlines
    float scanline = sin(uv.y * iResolution.y * 1.5) * 0.06;
    col -= scanline;

    // 2. Tape Grain / Static
    float noise = hash(uv + time_f) * 0.15;
    col += noise * (0.5 + amp_smooth);

    // 3. Acutance/Sharpening (Mockup)
    // Slightly washing out the blacks for that faded tape look
    col = pow(col, vec3(0.9));     // Gamma shift
    col += vec3(0.05, 0.02, 0.05); // Magnetic "noise floor" tint

    // 4. Signal Dropout (Horizontal white streaks)
    float dropout = step(0.995, hash(vec2(time_f, uv.y * 20.0)));
    col += dropout * 0.4;

    // Final Mapping & Inversion Glitch
    col = clamp(col, 0.0, 1.0);
    if (amp_peak > 0.96)
        col = 1.0 - col;

    col *= 0.8 + amp_smooth * 0.4;
    color = vec4(col, 1.0);
}