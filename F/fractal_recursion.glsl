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
    // Fetch audio - ensuring we don't get NaNs from empty textures
    float bass = texture(spectrum, 0.03).r;
    float mid = texture(spectrum, 0.22).r;
    float treble = texture(spectrum, 0.58).r;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    vec2 p = uv * (1.2 + bass * 0.3);

    // --- RECURSIVE FOLDING ---
    float scale = 1.0;
    float iter_sum = 0.0;
    const int iterations = 6; // Reduced iterations for cleaner geometry

    for (int i = 0; i < iterations; i++) {
        p = abs(p) - 0.5 - (mid * 0.05);
        p *= rot(time_f * 0.1 + float(i) * 0.5 + treble * 0.1);

        float s = 1.6 + bass * 0.1;
        p *= s;
        scale *= s;

        // Orbit trap: measure closeness to origin at this scale
        iter_sum += exp(-length(p) * 0.5);
    }

    // Normalizing coordinates for texture sampling
    vec2 sampUV = (p / scale) + 0.5;
    float chroma = treble * 0.02;

    // Sample texture with slight CA (Chromatic Aberration)
    vec3 tex;
    tex.r = texture(samp, sampUV + vec2(chroma, 0.0)).r;
    tex.g = texture(samp, sampUV).g;
    tex.b = texture(samp, sampUV - vec2(chroma, 0.0)).b;

    // --- COLOR COMPOSITION ---
    // Use the iteration sum to drive the fractal glow, but cap its influence
    vec3 fractalCol = crystal(iter_sum * 0.1 + time_f * 0.2);

    // Mix instead of just adding to prevent blowout
    vec3 col = mix(tex, fractalCol, clamp(iter_sum / float(iterations), 0.0, 1.0));

    // Additive highlights for "crystals"
    col += crystal(time_f) * (iter_sum * 0.2) * mid;

    // Subtle center lighting
    float light = 1.0 / (1.0 + length(uv) * 1.5);
    col *= (0.4 + light * 1.2);

    // Sparkle (Glitch)
    float sparkle = step(0.99, hash(p + time_f));
    col += sparkle * treble * 2.0;

    // --- FINAL MAPPING ---
    // Clamp before inversion to prevent negative color math
    col = clamp(col, 0.0, 1.0);

    // High-amplitude inversion
    if (amp_peak > 0.95) {
        col = 1.0 - col;
    }

    // Master brightness control
    col *= 0.7 + amp_smooth * 0.5;

    color = vec4(col, 1.0);
}