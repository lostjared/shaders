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


void main() {
    
    color = texture(samp, tc);
    vec2 uv = tc;
    uv.x -= 0.05;
    uv.y -= 0.05;
    vec4 color2 = texture(mat_samp, uv);
    color = mix(color, color2, 0.5);
}

