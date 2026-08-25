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

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;

void main(void) {
     color = texture(samp, tc);
    vec4 color2 = texture(samp, tc / 2);
    vec4 color3 = texture(samp, tc/ 4);
    vec4 color4 = texture(samp, tc/ 8);
    color[2] = (0.4 * color[2]) + (0.4 * color2[1]) + (0.4 * color3[1]) + (0.4 * color4[0]);
    color[1] = (0.4 * color[1]) + (0.4 * color2[1]) + (0.4 * color3[2]) + (0.4 * color4[0]);
    color[0] = (0.4 * color[0]) + (0.4 * color2[2]) + (0.4 * color3[2]) + (0.4 * color4[1]);
}