#version 330

in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform sampler1D spectrum;

// Mirror across the vertical axis with twist strength tied to mid frequencies.
void main(void) {
    float mid = texture(spectrum, 0.35).r;
    float bass = texture(spectrum, 0.05).r;

    vec2 uv = tc;
    if (uv.x > 0.5) uv.x = 1.0 - uv.x;
    uv.x *= 2.0;

    vec2 center = vec2(0.5);
    vec2 d = uv - center;
    float radius = length(d);

    float twistStrength = 1.0 + mid * 6.0;
    float angle = twistStrength * (radius - 1.0) + time_f * (1.0 + bass * 2.0);
    float c = cos(angle), s = sin(angle);
    vec2 twistedTC = mat2(c, -s, s, c) * d + center;
    twistedTC.x = mix(twistedTC.x, 1.0 - twistedTC.x, step(0.5, tc.x));

    float ripple = sin(tc.x * 10.0 + time_f * 5.0) * 0.03;
    ripple += sin(tc.y * 10.0 + time_f * 5.0) * 0.03;
    vec2 rippleTC = tc + vec2(ripple);

    color = texture(samp, mix(rippleTC, twistedTC, 0.5));
}
