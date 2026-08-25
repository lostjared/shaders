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
#define time_f ext.u2.y

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;


void main(void) {
    vec2 redOffset = vec2(sin(time_f * 5.0), cos(time_f * 5.0)) * 0.02;
    vec2 greenOffset = vec2(cos(time_f * 7.0), sin(time_f * 7.0)) * 0.02;
    vec2 blueOffset = vec2(sin(time_f * 3.0), cos(time_f * 3.0)) * 0.02;

    vec4 redChannel = texture(samp, tc + redOffset);
    vec4 greenChannel = texture(samp, tc + greenOffset);
    vec4 blueChannel = texture(samp, tc + blueOffset);

    color = vec4(redChannel.r, greenChannel.g, blueChannel.b, 1.0);
}
