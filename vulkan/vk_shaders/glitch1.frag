#version 450

layout(set = 0, binding = 1, std140) uniform SpriteExtended {
    vec4 mouse;
    vec4 u0;
    vec4 u1;
    vec4 u2;
    vec4 u3;
    vec4 custom_uniforms[16];
    vec4 audio_bands;
    vec4 audio_history;
} ext;
#define iMouse ext.mouse
#define iResolution ext.u0.zw
#define time_f ext.u2.y

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;

layout(set = 0, binding = 0) uniform sampler2D samp;



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
