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
    vec2 mirrored_tc = abs(fract(tc) - 0.5) + 0.5;
    vec4 color1 = texture(samp, mirrored_tc);
    vec4 color2 = texture(samp, mirrored_tc * 0.5);
    vec4 color3 = texture(samp, mirrored_tc * 0.25);
    vec4 color4 = texture(samp, mirrored_tc * 0.125);
    color = (color1 * 0.4) + (color2 * 0.3) + (color3 * 0.2) + (color4 * 0.1);
}

