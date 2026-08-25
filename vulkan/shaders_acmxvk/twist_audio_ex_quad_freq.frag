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

// Each screen quadrant twists with its own frequency band.
void main(void) {
    float q0 = texture(spectrum, 0.05).r;
    float q1 = texture(spectrum, 0.25).r;
    float q2 = texture(spectrum, 0.50).r;
    float q3 = texture(spectrum, 0.80).r;

    float e;
    if (tc.x < 0.5 && tc.y < 0.5) e = q0;
    else if (tc.x >= 0.5 && tc.y < 0.5) e = q1;
    else if (tc.x < 0.5 && tc.y >= 0.5) e = q2;
    else e = q3;

    vec2 center = vec2(0.5);
    vec2 d = tc - center;
    float radius = length(d);

    float twistStrength = 0.5 + e * 8.0;
    float angle = twistStrength * (radius - 1.0) + time_f;
    float c = cos(angle), s = sin(angle);
    vec2 twistedTC = mat2(c, -s, s, c) * d + center;

    float ripple = sin(tc.x * 10.0 + time_f * 5.0) * (0.02 + e * 0.04);
    ripple += sin(tc.y * 10.0 + time_f * 5.0) * (0.02 + e * 0.04);
    vec2 rippleTC = tc + vec2(ripple);

    color = texture(samp, mix(rippleTC, twistedTC, 0.5));
}
