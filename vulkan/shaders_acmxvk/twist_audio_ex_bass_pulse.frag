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

// Bass pulses drive overall twist strength and ripple amplitude.
void main(void) {
    float bass = texture(spectrum, 0.03).r;
    float rippleSpeed = 5.0;
    float rippleAmplitude = 0.02 + bass * 0.08;
    float rippleWavelength = 10.0;
    float twistStrength = 0.5 + bass * 6.0;

    vec2 center = vec2(0.5);
    float radius = length(tc - center);
    float ripple = sin(tc.x * rippleWavelength + time_f * rippleSpeed) * rippleAmplitude;
    ripple += sin(tc.y * rippleWavelength + time_f * rippleSpeed) * rippleAmplitude;
    vec2 rippleTC = tc + vec2(ripple);

    float angle = twistStrength * (radius - 1.0) + time_f;
    float c = cos(angle), s = sin(angle);
    vec2 twistedTC = mat2(c, -s, s, c) * (tc - center) + center;

    color = texture(samp, mix(rippleTC, twistedTC, 0.5));
}
