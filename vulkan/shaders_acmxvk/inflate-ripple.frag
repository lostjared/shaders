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
#define time_f ext.u2.y

layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    float cycle_time = mod(time_f, 5.0);
    float inflate = min(cycle_time * 0.4, 1.5);
    vec2 center = vec2(0.5, 0.5);
    float distance = length(tc - center);
    float ripple = sin((distance - cycle_time) * 10.0) * 0.02;

    vec2 adjusted_tc = (tc - center) * inflate + center + normalize(tc - center) * ripple;
    color = texture(samp, adjusted_tc);
}
