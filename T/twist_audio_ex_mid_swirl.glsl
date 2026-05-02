#version 330

in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform sampler1D spectrum;

// Mid-range frequencies steer the swirl direction and rotation speed.
void main(void) {
    float mid = texture(spectrum, 0.25).r;
    float midHi = texture(spectrum, 0.40).r;
    float dir = sign(midHi - mid);
    if (dir == 0.0)
        dir = 1.0;

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
