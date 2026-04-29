#version 330

in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform sampler1D spectrum;

// Spectrum is wrapped along the spiral, twisting more where energy is highest.
void main(void) {
    vec2 center = vec2(0.5);
    vec2 d = tc - center;
    float radius = length(d);
    float theta = atan(d.y, d.x);

    float idx = fract((theta / 6.2831853) + radius + time_f * 0.1);
    float e = texture(spectrum, idx).r;

    float ripple = sin(tc.x * 10.0 + time_f * 5.0) * 0.03;
    ripple += sin(tc.y * 10.0 + time_f * 5.0) * 0.03;
    vec2 rippleTC = tc + vec2(ripple);

    float twistStrength = 1.0 + e * 6.0;
    float angle = twistStrength * (radius - 1.0) + time_f + e * 3.0;
    float c = cos(angle), s = sin(angle);
    vec2 twistedTC = mat2(c, -s, s, c) * d + center;

    color = texture(samp, mix(rippleTC, twistedTC, 0.5));
}
