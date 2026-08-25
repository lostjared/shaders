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
    float tear1 = sin(tc.x * 10.0 + time_f * 5.0) * 0.05;
    float tear2 = sin(tc.x * 20.0 + time_f * 7.0) * 0.03;
    float tear3 = sin(tc.x * 30.0 + time_f * 9.0) * 0.02;
    
    float combined_tear = tear1 + tear2 + tear3;
    vec2 new_tc = vec2(tc.x + combined_tear, tc.y + combined_tear);
    color = texture(samp, new_tc);
}
