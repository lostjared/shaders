#version 330

in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform sampler1D spectrum;

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
