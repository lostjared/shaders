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
    vec2 normCoord = (tc * 2.0 - 1.0) * vec2(iResolution.x / iResolution.y, 1.0);
    float dist = length(normCoord);
    float cycleDuration = 10.0;
    float cyclePhase = mod(time_f, cycleDuration) / cycleDuration;
    float effectPhase = cyclePhase < 0.5 ? cyclePhase * 2.0 : (1.0 - cyclePhase) * 2.0;
    float effectRadius = 0.75 * sin(effectPhase * 3.14159);
    if (dist < effectRadius) {
        float effectStrength = 10.0 - (dist / effectRadius);
        normCoord *= 1.0 + effectStrength * (effectRadius - dist) * sin(effectPhase * 3.14159);
    }
    vec2 finalCoord = (normCoord / vec2(iResolution.x / iResolution.y, 1.0) + 1.0) / 2.0;
    color = texture(samp, finalCoord);
}
