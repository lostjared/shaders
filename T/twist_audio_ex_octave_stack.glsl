#version 330

in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform sampler1D spectrum;

// Five octave-spaced spectrum samples stack into a single rich twist amount.
void main(void) {
    float sum = 0.0;
    float amp = 1.0;
    float pos = 0.02;
    for (int i = 0; i < 5; ++i) {
        sum += texture(spectrum, pos).r * amp;
        pos *= 2.0;
        amp *= 0.6;
    }
    sum *= 0.7;

    vec2 center = vec2(0.5);
    vec2 d = tc - center;
    float radius = length(d);

    float twistStrength = 1.0 + sum * 5.0;
    float angle = twistStrength * (radius - 1.0) + time_f * (1.0 + sum * 1.5);
    float c = cos(angle), s = sin(angle);
    vec2 twistedTC = mat2(c, -s, s, c) * d + center;

    float ripple = sin(tc.x * (8.0 + sum * 8.0) + time_f * 5.0) * (0.02 + sum * 0.04);
    ripple += sin(tc.y * (8.0 + sum * 8.0) + time_f * 5.0) * (0.02 + sum * 0.04);
    vec2 rippleTC = tc + vec2(ripple);

    color = texture(samp, mix(rippleTC, twistedTC, 0.5));
}
