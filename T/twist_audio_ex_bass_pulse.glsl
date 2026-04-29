#version 330

in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform sampler1D spectrum;

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
