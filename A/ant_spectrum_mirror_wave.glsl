#version 330 core
// ant_spectrum_mirror_wave
// Dual-axis mirror with sine wave distortion, echo ripples, and gradient wash

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

const float PI = 3.14159265;

vec3 rainbow(float t) {
    return 0.5 + 0.5 * cos(6.28318 * (t + vec3(0.0, 0.33, 0.67)));
}

vec2 mirror(vec2 uv) {
    vec2 m = mod(uv, 2.0);
    return mix(m, 2.0 - m, step(1.0, m));
}

void main() {
    float bass = texture(spectrum, 0.03).r;
    float mid = texture(spectrum, 0.20).r;
    float hiMid = texture(spectrum, 0.36).r;
    float treble = texture(spectrum, 0.55).r;
    float air = texture(spectrum, 0.80).r;

    vec2 uv = tc;
    vec2 centered = uv - 0.5;

    // Wave mirror: sin-bent axes
    float waveX = sin(centered.y * PI * (4.0 + bass * 4.0) + iTime * 2.0) * 0.1 * bass;
    float waveY = sin(centered.x * PI * (4.0 + mid * 4.0) + iTime * 1.5) * 0.1 * mid;
    centered.x = abs(centered.x + waveX);
    centered.y = abs(centered.y + waveY);

    // Additional fold
    if (centered.y > centered.x)
        centered = centered.yx;

    uv = centered + 0.5;

    // Ripple echo: concentric wave distortions
    float dist = length(centered);
    vec3 result = vec3(0.0);
    for (float e = 0.0; e < 5.0; e++) {
        float ripple = sin(dist * (20.0 + hiMid * 15.0) - iTime * 3.0 + e * PI * 0.4) * 0.015;
        vec2 ripUV = mirror(uv + ripple * normalize(centered + 0.001));
        vec3 s = texture(samp, ripUV).rgb;
        s *= rainbow(e * 0.2 + dist * 2.0 + iTime * 0.25);
        result += s * (1.0 / (1.0 + e * 0.4));
    }
    result /= 2.5;

    // Color shifting gradient
    vec3 grad = rainbow(dist * 3.0 + iTime * 0.4 + bass);
    result = mix(result, result * grad, 0.35 + treble * 0.25);

    // Channel rotation
    float shift = sin(iTime * 0.7) * 0.5 + 0.5;
    result = mix(result, result.gbr, shift * mid);

    // Air
    result += air * 0.08 * vec3(0.6, 0.8, 1.0);

    result *= 0.9 + amp_smooth * 0.25;
    result = mix(result, vec3(1.0) - result, smoothstep(0.9, 1.0, amp_peak));

    color = vec4(result, 1.0);
}
