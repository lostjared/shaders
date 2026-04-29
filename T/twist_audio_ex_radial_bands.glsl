#version 330

in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform sampler1D spectrum;

// Twist strength is sampled radially from the spectrum: inner = bass, outer = treble.
void main(void) {
    vec2 center = vec2(0.5);
    vec2 d = tc - center;
    float radius = length(d);

    float band = clamp(radius * 1.4, 0.0, 1.0);
    float energy = texture(spectrum, band).r;

    float ripple = sin(tc.x * 10.0 + time_f * 5.0) * 0.03;
    ripple += sin(tc.y * 10.0 + time_f * 5.0) * 0.03;
    vec2 rippleTC = tc + vec2(ripple);

    float twistStrength = 0.5 + energy * 8.0;
    float angle = twistStrength * (radius - 1.0) + time_f;
    float c = cos(angle), s = sin(angle);
    vec2 twistedTC = mat2(c, -s, s, c) * d + center;

    color = texture(samp, mix(rippleTC, twistedTC, 0.5));
}
