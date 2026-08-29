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

// Mid-range frequencies steer the swirl direction and rotation speed.
void main(void) {
    float mid = texture(spectrum, 0.25).r;
    float midHi = texture(spectrum, 0.40).r;
    float dir = sign(midHi - mid);
    if (dir == 0.0) dir = 1.0;

    float rippleAmplitude = 0.03;
    float rippleWavelength = 10.0 + mid * 18.0;
    vec2 center = vec2(0.5);
    float radius = length(tc - center);
    float ripple = sin(tc.x * rippleWavelength + time_f * 5.0) * rippleAmplitude;
    ripple += sin(tc.y * rippleWavelength + time_f * 5.0) * rippleAmplitude;
    vec2 rippleTC = tc + vec2(ripple);

    float twistStrength = 1.0 + mid * 4.0;
    float angle = dir * (twistStrength * (radius - 1.0) + time_f * (1.0 + mid * 2.0));
    float c = cos(angle), s = sin(angle);
    vec2 twistedTC = mat2(c, -s, s, c) * (tc - center) + center;

    color = texture(samp, mix(rippleTC, twistedTC, 0.5));
}
