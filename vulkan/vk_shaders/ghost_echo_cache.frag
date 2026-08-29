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
#define history_head int(ext.u3.x)
#define iResolution ext.u0.zw
#define time_f ext.u2.y

// Ghost Echo — Classic trailing afterimage effect
// Each cache frame is blended with exponential decay, creating persistent
// ghostly echoes that fade smoothly into the past.
layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;
layout(set = 0, binding = 2) uniform sampler2DArray history;

#ifndef SIZE
#define SIZE 8
#endif
#ifndef CACHE_HISTORY_LAYER
#define CACHE_HISTORY_LAYER(index) ((history_head + (index)) % SIZE)
#endif



void main(void) {
    vec4 current = texture(samp, tc);

    // Exponential decay weights: newest cache is strongest, oldest faintest
    float w1 = 0.50;
    float w2 = 0.35;
    float w3 = 0.24;
    float w4 = 0.16;
    float w5 = 0.10;
    float w6 = 0.06;
    float w7 = 0.03;
    float w8 = 0.015;

    // Slight UV drift per frame — ghosts slowly wander
    float drift = 0.003;
    vec2 d1 = vec2(sin(time_f * 0.7) * drift, cos(time_f * 0.5) * drift);
    vec2 d2 = d1 * 2.1;
    vec2 d3 = d1 * 3.3;
    vec2 d4 = d1 * 4.6;
    vec2 d5 = d1 * 5.8;
    vec2 d6 = d1 * 7.0;
    vec2 d7 = d1 * 8.3;
    vec2 d8 = d1 * 9.5;

    vec4 ghost = texture(history, vec3(tc + d1, float(CACHE_HISTORY_LAYER(0)))) * w1
               + texture(history, vec3(tc + d2, float(CACHE_HISTORY_LAYER(1)))) * w2
               + texture(history, vec3(tc + d3, float(CACHE_HISTORY_LAYER(2)))) * w3
               + texture(history, vec3(tc + d4, float(CACHE_HISTORY_LAYER(3)))) * w4
               + texture(history, vec3(tc + d5, float(CACHE_HISTORY_LAYER(4)))) * w5
               + texture(history, vec3(tc + d6, float(CACHE_HISTORY_LAYER(5)))) * w6
               + texture(history, vec3(tc + d7, float(CACHE_HISTORY_LAYER(6)))) * w7
               + texture(history, vec3(tc + d8, float(CACHE_HISTORY_LAYER(7)))) * w8;

    // Normalize the ghost accumulation
    float totalW = w1 + w2 + w3 + w4 + w5 + w6 + w7 + w8;
    ghost /= totalW;

    // Cool tint on ghosts — shift toward blue/cyan as they age
    ghost.rgb = mix(ghost.rgb, ghost.rgb * vec3(0.7, 0.85, 1.1), 0.3);

    // Blend: current frame dominates, ghosts add behind
    float ghostStrength = 0.55 + 0.1 * sin(time_f * 0.8);
    color = vec4(mix(current.rgb, max(current.rgb, ghost.rgb), ghostStrength), 1.0);
}
