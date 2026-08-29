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

    float glitchStrength = sin(time_f * 10.0) * 0.1;
    float glitchOffsetX = fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453) * glitchStrength;
    float glitchOffsetY = fract(cos(dot(uv, vec2(4.898, 7.23))) * 23421.6312) * glitchStrength;

    uv.x += glitchOffsetX;
    uv.y += glitchOffsetY;

    vec4 colorA = texture(samp, uv);
    vec4 colorB = texture(samp, uv + vec2(0.01 * sin(time_f * 50.0), 0.01 * cos(time_f * 50.0)));

    float noise = fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
    color = mix(colorA, colorB, noise);
}
