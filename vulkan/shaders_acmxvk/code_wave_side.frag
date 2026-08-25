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


void main(void) {
    float xNorm = (gl_FragCoord.x / iResolution.x) * 2.0 - 1.0;
    float phase = abs(sin(time_f * 2.0));
    vec2 tcAdjusted = tc + vec2(phase * xNorm * 0.305, 0);
    color = texture(samp, tcAdjusted);
}
