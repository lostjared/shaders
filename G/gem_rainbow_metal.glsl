#version 330 core
in vec2 tc;
out vec4 color;

uniform float time_f;
uniform sampler2D samp;
uniform vec2 iResolution;

// High-fidelity spectrum for the oily "fringe" colors
vec3 spectrum(float t) {
    return vec3(0.5 + 0.5 * cos(6.28318 * (t + vec3(0.0, 0.33, 0.67))));
}

void main(void) {
    // 1. Setup coordinates
    vec2 uv = tc * 2.0 - 1.0;
    uv.x *= iResolution.x / iResolution.y;

    float r = length(uv);
    float angle = atan(uv.y, uv.x);

    // 2. The Zig-Zag Ripples (Complexity)
    // We combine multiple sine waves to get a jagged, non-uniform edge
    float ripple = sin(angle * 10.0 + time_f) * 0.03;
    ripple += sin(angle * 25.0 - time_f * 2.0) * 0.01; // Secondary fine detail

    // 3. Radial Wave Logic
    float wave = sin(r * 20.0 - time_f * 4.0 + ripple * 10.0);

    // 4. Chromatic Aberration Distortion
    // We sample the texture 3 times. The ripple intensity determines the "split".
    float shift = ripple * 0.5 + wave * 0.01;

    float r_chan = texture(samp, tc + vec2(shift, 0.0)).r;
    float g_chan = texture(samp, tc).g;
    float b_chan = texture(samp, tc - vec2(shift, 0.0)).b;
    vec3 baseTex = vec3(r_chan, g_chan, b_chan);

    // 5. Psychedelic Coloring
    // Only apply the rainbow where the "waves" are strongest
    vec3 rainbow = spectrum(r - time_f * 0.5 + ripple);
    float glowMask = smoothstep(0.5, 1.0, wave); // Sharpen the color bands

    // 6. Central Highlight
    // Replicating the bright white "eye" center
    float center = exp(-r * 6.0);
    vec3 coreGlow = vec3(1.0, 0.98, 0.9) * center * 1.5;

    // 7. Final Composite
    // Subtle blend to keep it recognizable but "electric"
    vec3 finalColor = mix(baseTex, rainbow, glowMask * 0.35);
    finalColor += coreGlow;

    // Add a bit of metallic "sheen" to the edges of the ripples
    finalColor += (wave * ripple * 2.0);

    color = vec4(finalColor, 1.0);
}