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
    vec2 uv = tc * 2.0 - 1.0;
    uv *= iResolution.x / iResolution.y;
    float r = length(uv);
    float theta = atan(uv.y, uv.x);
    float spiralEffect = time_f * 0.2;
    r -= mod(spiralEffect, 4.0);
    theta += spiralEffect;
    vec2 distorted_uv = vec2(cos(theta), sin(theta)) * r;
    distorted_uv = (distorted_uv / (iResolution.x / iResolution.y)) * 0.5 + 0.5;

    vec4 texColor = texture(samp, distorted_uv);
    color = vec4(texColor.rgb, 1.0);
}
