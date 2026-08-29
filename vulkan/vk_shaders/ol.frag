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
#define frequency ext.custom_uniforms[6].x
#define iMouse ext.mouse
#define iResolution ext.u0.zw
#define strength ext.custom_uniforms[6].y
#define time_f ext.u2.y

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;

layout(set = 0, binding = 0) uniform sampler2D samp;         // Texture sampler



// Parameters to control the glitch effect



void main() {
    vec2 warpedTexCoord = tc;

    // Add noise-based distortion
    float noise = fract(sin(warpedTexCoord.x * frequency + time_f) *
4.0);
    noise += fract(sin(warpedTexCoord.y * frequency * 2.0 + time_f) *
2.0);
    noise *= strength;

    // Combine with mouse position for interactive warping
    vec2 mousePos = iMouse.xy;
    mousePos.x = sin(mousePos.x * 16.0 + time_f);
    mousePos.y = sin(mousePos.y * 16.0 + time_f);

    warpedTexCoord += noise * mousePos * strength;

    // Apply multiple layers of distortion
    float layer1 = fract(sin(tc.x * 4.0 + time_f) * 2.0);
    float layer2 = fract(sin(tc.y * 4.0 * 2.0 + time_f) * 2.0);
    float layer3 = fract(sin((tc.x + tc.y) * 8.0 + time_f) * 1.0);

    // Combine all layers
    vec2 finalTexCoord = tc + (layer1 + layer2 * mousePos.x + layer3 *
mousePos.y) * strength;

    color = mix(texture(samp, sin(finalTexCoord * time_f)), texture(samp, tc), 0.5);
}