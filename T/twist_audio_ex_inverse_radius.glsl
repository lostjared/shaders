#version 330

in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform sampler1D spectrum;

// Twist increases sharply toward the center, modulated by bass.
void main(void) {
    float bass = texture(spectrum, 0.05).r;

    vec2 center = vec2(0.5);
    vec2 d = tc - center;
    float radius = length(d);

    float twistStrength = (1.0 + bass * 5.0) / (radius + 0.15);
    float angle = twistStrength * (1.0 - radius) + time_f;
    float c = cos(angle), s = sin(angle);
    vec2 twistedTC = mat2(c, -s, s, c) * d + center;

    float ripple = sin(tc.x * 10.0 + time_f * 5.0) * 0.03;
    ripple += sin(tc.y * 10.0 + time_f * 5.0) * 0.03;
    vec2 rippleTC = tc + vec2(ripple);

    color = texture(samp, mix(rippleTC, twistedTC, 0.5));
}
