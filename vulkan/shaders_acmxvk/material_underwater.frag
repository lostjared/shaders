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
uniform sampler2D mat_samp;


void main(void) {
    vec2 wave_tc = tc + vec2(sin(tc.y * 10.0 + time_f), cos(tc.x * 10.0 + time_f)) * 0.05;
    vec4 color_samp = texture(samp, wave_tc);
    vec4 color_mat_samp = texture(mat_samp, wave_tc);
    
    vec4 texture_color = mix(color_samp, color_mat_samp, 0.5);
    
    color = texture_color;
}
