#version 330 core
// Ghost Echo — Classic trailing afterimage effect
// Each cache frame is blended with exponential decay, creating persistent
// ghostly echoes that fade smoothly into the past.

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform sampler2D samp1;
uniform sampler2D samp2;
uniform sampler2D samp3;
uniform sampler2D samp4;
uniform sampler2D samp5;
uniform sampler2D samp6;
uniform sampler2D samp7;
uniform sampler2D samp8;

uniform vec2 iResolution;
uniform float time_f;

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

    vec4 ghost = texture(samp1, tc + d1) * w1
               + texture(samp2, tc + d2) * w2
               + texture(samp3, tc + d3) * w3
               + texture(samp4, tc + d4) * w4
               + texture(samp5, tc + d5) * w5
               + texture(samp6, tc + d6) * w6
               + texture(samp7, tc + d7) * w7
               + texture(samp8, tc + d8) * w8;

    // Normalize the ghost accumulation
    float totalW = w1 + w2 + w3 + w4 + w5 + w6 + w7 + w8;
    ghost /= totalW;

    // Cool tint on ghosts — shift toward blue/cyan as they age
    ghost.rgb = mix(ghost.rgb, ghost.rgb * vec3(0.7, 0.85, 1.1), 0.3);

    // Blend: current frame dominates, ghosts add behind
    float ghostStrength = 0.55 + 0.1 * sin(time_f * 0.8);
    color = vec4(mix(current.rgb, max(current.rgb, ghost.rgb), ghostStrength), 1.0);
}
