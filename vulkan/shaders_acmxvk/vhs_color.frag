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

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;



const float TAU = 6.28318530718;

vec3 vhs_palette(float t) {
    vec3 a = vec3(0.5, 0.45, 0.5);
    vec3 b = vec3(0.6, 0.72, 0.95);
    vec3 c = vec3(0.85, 0.2, 0.25);
    vec3 d = vec3(0.3, 0.15, 0.2);
    return a + b * cos(TAU * (c * t + d)) - vec3(0.08) * sin(time_f * 0.3) +
           (t > 0.8 ? vec3(0.1) : vec3(0));
}

void main(void) {
    vec4 col = texture(samp, tc);
    color = vec4(col.rgb * vhs_palette(time_f), col.a);
}