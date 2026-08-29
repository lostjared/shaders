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

layout(set = 0, binding = 3) uniform sampler1D spectrum;

// Discrete concentric rings each pick a different spectrum bin, twisting in alternating directions.
void main(void) {
    vec2 center = vec2(0.5);
    vec2 d = tc - center;
    float radius = length(d);

    float rings = 6.0;
    float ringIdx = floor(radius * rings);
    float bin = (ringIdx + 0.5) / rings;
    float e = texture(spectrum, bin).r;
    float dir = mod(ringIdx, 2.0) < 0.5 ? 1.0 : -1.0;

    float twistStrength = 1.0 + e * 6.0;
    float angle = dir * (twistStrength * (radius - 1.0) + time_f);
    float c = cos(angle), s = sin(angle);
    vec2 twistedTC = mat2(c, -s, s, c) * d + center;

    float ripple = sin(tc.x * 10.0 + time_f * 5.0) * 0.03;
    ripple += sin(tc.y * 10.0 + time_f * 5.0) * 0.03;
    vec2 rippleTC = tc + vec2(ripple);

    color = texture(samp, mix(rippleTC, twistedTC, 0.5));
}
