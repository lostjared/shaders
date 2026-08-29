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
    vec2 normPos = gl_FragCoord.xy / iResolution.xy;
    float cycle = sin(time_f * 0.5);
    float movingPhase = normPos.x + cycle;
    float phase = sin(movingPhase * 10.0 - time_f * 2.0);
    vec2 tcAdjusted = tc + (vec2(phase, 0) * 0.302);

    float glitchFactor = sin(time_f);
    vec2 glitchOffset = vec2(glitchFactor * 0.1, glitchFactor * 0.1);
    vec4 glitchColor = texture(samp, tc + glitchOffset);

    vec4 baseColor = texture(samp, tcAdjusted);
    color = mix(baseColor, glitchColor, 0.5);
}






