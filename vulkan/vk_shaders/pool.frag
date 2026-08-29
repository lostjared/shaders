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

layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;


void main(void) {
    float time_t = mod(time_f, 100);
    float scale = time_t;
    float speed = 16.0;
    float offset = sin(time_f * speed + tc.x * scale) * 0.05;
    vec2 tcOffset = vec2(tc.x, tc.y + offset);
   color = texture(samp, tcOffset);
}
