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
    float amplitude = sin(time_f * 5.0) * 2.0;
    float distFromCenter = abs(tc.y - 0.5);
    vec2 distorted_tc = tc;
    distorted_tc.y += amplitude * (0.5 - distFromCenter) * distFromCenter;
    distorted_tc = clamp(distorted_tc, vec2(0.0), vec2(1.0));
    color = texture(samp, distorted_tc);
}
