#version 330

in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform sampler1D spectrum;

// Twist amplitude sine-modulates with each spectrum sample creating breathing waves.
void main(void) {
    float lo = texture(spectrum, 0.08).r;
    float md = texture(spectrum, 0.32).r;
    float hi = texture(spectrum, 0.70).r;

    vec2 center = vec2(0.5);
    vec2 d = tc - center;
    float radius = length(d);

    float wave = sin(time_f * 2.0) * lo + sin(time_f * 3.7 + 1.3) * md + sin(time_f * 5.5 + 2.1) * hi;

    float twistStrength = 1.0 + wave * 4.0;
    float angle = twistStrength * (radius - 1.0) + time_f;
    float c = cos(angle), s = sin(angle);
    vec2 twistedTC = mat2(c, -s, s, c) * d + center;

    float ripple = sin(tc.x * 10.0 + time_f * 5.0) * 0.03;
    ripple += sin(tc.y * 10.0 + time_f * 5.0) * 0.03;
    vec2 rippleTC = tc + vec2(ripple);

    color = texture(samp, mix(rippleTC, twistedTC, 0.5));
}
