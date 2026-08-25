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
    float frostAmount = 0.1;
    float frostScale = 3.0;
    vec2 noiseOffset = vec2(time_f * 0.02, time_f * -0.02);
    vec2 noiseTC = tc * frostScale + noiseOffset;
    float noiseValue = texture(mat_samp, noiseTC).r;
    vec2 distortedTC = tc + (noiseValue - 0.5) * frostAmount;

    vec4 sceneColor = texture(samp, distortedTC);

    color = mix(texture(samp, tc), sceneColor, noiseValue * frostAmount);
}
