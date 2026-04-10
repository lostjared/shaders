#version 330 core
in vec2 tc;
out vec4 color;
uniform float time_f;
uniform sampler2D samp;
uniform vec2 iResolution;
uniform vec4 iMouse;

// Helper Functions
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

vec2 glitchOffset(vec2 uv, vec2 seed) {
    float strength = random(seed) * 0.1 - 0.05; // Random strength
    if (random(seed * 2.0 + time_f) > 0.5) {
        uv.y += strength; // Horizontal distortion
    } else {
        uv.x += strength; // Vertical distortion
    }
    return uv;
}

void main(void) {
    vec2 uv = tc;

    // Random seed based on uv and time
    vec2 seed = floor(uv * 10.0) + vec2(time_f);

    // Apply glitch offset
    vec2 glitch_uv = glitchOffset(uv, seed);

    // Sample the texture with the distorted coordinates
    vec4 texColor = texture(samp, glitch_uv);

    // Additional glitch color distortions
    float glitch_strength = random(seed) * 0.3;
    if (random(seed + 1.0) > 0.7) {
        texColor.r += glitch_strength;
        texColor.g -= glitch_strength;
    }

    color = texColor;
}
