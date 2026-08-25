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

// Spectrum bands pick the ripple wavelengths, the twist follows the energy sum.
void main(void) {
    float lo = texture(spectrum, 0.10).r;
    float md = texture(spectrum, 0.35).r;
    float hi = texture(spectrum, 0.70).r;
    float total = lo + md + hi;

    vec2 center = vec2(0.5);
    vec2 d = tc - center;
    float radius = length(d);

    float wavelength = 6.0 + lo * 8.0 + md * 10.0 + hi * 16.0;
    float amp = 0.02 + total * 0.02;
    float ripple = sin(tc.x * wavelength + time_f * (4.0 + hi * 6.0)) * amp;
    ripple += sin(tc.y * wavelength + time_f * (4.0 + lo * 6.0)) * amp;
    vec2 rippleTC = tc + vec2(ripple);

    float twistStrength = 0.5 + total * 2.0;
    float angle = twistStrength * (radius - 1.0) + time_f;
    float c = cos(angle), s = sin(angle);
    vec2 twistedTC = mat2(c, -s, s, c) * d + center;

    color = texture(samp, mix(rippleTC, twistedTC, 0.5));
}
