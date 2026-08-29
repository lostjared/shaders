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
    vec2 uv = tc;
    float warpX = tan(uv.y * 10.0 + time_f) * 0.1;
    float warpY = tan(uv.x * 10.0 + time_f) * 0.1;
    uv.x += warpX;
    uv.y += warpY;
    color = texture(samp, sin(uv * time_f));
}

