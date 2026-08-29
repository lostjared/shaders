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
#define iResolution ext.u0.zw
#define uamp ext.u1.y

layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec2 uv = tc * 2.0 - 1.0; // Transform texture coordinates to [-1, 1]
    float len = length(uv); // Distance from the center
    float bubble = smoothstep(0.7, 1.0, 1.0 - len); // Bubble shape effect

    // Beat effect: the bubble size and distortion intensity are modulated by uamp
    float beat = 1.0 + 0.2 * sin(uamp * 100.0); // Beat modulation frequency scaled by uamp
    vec2 distort = uv * (1.0 + 0.15 * sin(len * 20.0 * beat)); // Distortion based on the beat
    
    vec4 texColor = texture(samp, distort * 0.5 + 0.5); // Sample the texture with distortion
    color = mix(texColor, vec4(1.0, 1.0, 1.0, 1.0), bubble * uamp); // Blend texture and bubble
}
