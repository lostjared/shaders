#version 330

in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform sampler1D spectrum;

// Spectrum is sampled by polar angle so the twist forms angular petals of energy.
void main(void) {
    vec2 center = vec2(0.5);
    vec2 d = tc - center;
    float radius = length(d);
    float theta = atan(d.y, d.x);

    float idx = fract(theta / 6.2831853 + 0.5 + time_f * 0.05);
    float e = texture(spectrum, idx).r;

    float twistStrength = 1.0 + e * 8.0;
    float angle = twistStrength * (radius - 1.0) + time_f + e * 2.0;
    float c = cos(angle), s = sin(angle);
    vec2 twistedTC = mat2(c, -s, s, c) * d + center;

    float ripple = sin(tc.x * 10.0 + time_f * 5.0) * (0.03 + e * 0.03);
    ripple += sin(tc.y * 10.0 + time_f * 5.0) * (0.03 + e * 0.03);
    vec2 rippleTC = tc + vec2(ripple);

    color = texture(samp, mix(rippleTC, twistedTC, 0.5));
}
