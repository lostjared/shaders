#version 330 core

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float iTime;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

void main() {
    vec2 uv = tc;

    // 1. Recursive Spatial Melting
    // Instead of horizontal rips, let's do a spiral warp driven by the spectrum.
    float bass = texture(spectrum, 0.05).r;
    float mid = texture(spectrum, 0.2).r;

    vec2 centered = uv - 0.5;
    float dist = length(centered);
    float angle = atan(centered.y, centered.x);

    // Twist the image based on bass and distance
    angle += (bass * 4.0) * exp(-dist);
    centered = vec2(cos(angle), sin(angle)) * dist;
    uv = centered + 0.5;

    // 2. The "Frequency Smear"
    // Use the spectrum to create multiple ghost samples
    vec3 result = texture(samp, uv).rgb;
    for (float i = 1.0; i < 4.0; i++) {
        float freq_sample = texture(spectrum, i * 0.1).r;
        vec2 offset = vec2(freq_sample * 0.05 * i, 0.0);
        result = mix(result, texture(samp, uv + offset).rgb, 0.5);
    }

    // 3. Fluid Color Inversion
    // Instead of 'if', we use smoothstep to fade into the negative
    vec3 negative = 1.0 - result;
    float shift_trigger = smoothstep(0.3, 0.8, amp_smooth + mid);
    result = mix(result, negative, shift_trigger);

    // 4. Harmonic Glow
    // Add a color tint based on where the energy is in the spectrum
    vec3 glow = vec3(bass, mid, texture(spectrum, 0.6).r);
    result += glow * 0.3;

    // 5. The "Null" Transient
    // Let's keep the black-out but make it a very fast fade
    result *= (1.0 - smoothstep(0.95, 1.0, amp_peak));

    color = vec4(result, 1.0);
}