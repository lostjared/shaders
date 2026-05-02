#version 330

in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform sampler1D spectrum;

// Treble dusts the twist with grainy pixel-level offsets.
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void main(void) {
    float treble = texture(spectrum, 0.65).r;
    float air = texture(spectrum, 0.90).r;

    vec2 grain = (vec2(hash(tc * 1024.0 + time_f), hash(tc * 1024.0 - time_f)) - 0.5) * (treble + air) * 0.04;

    vec2 center = vec2(0.5);
    vec2 d = (tc + grain) - center;
    float radius = length(d);

    float angle = (1.0 + treble * 3.0) * (radius - 1.0) + time_f;
    float c = cos(angle), s = sin(angle);
    vec2 twistedTC = mat2(c, -s, s, c) * d + center;

    float ripple = sin(tc.x * 10.0 + time_f * 5.0) * 0.03;
    ripple += sin(tc.y * 10.0 + time_f * 5.0) * 0.03;
    vec2 rippleTC = tc + vec2(ripple);

    color = texture(samp, mix(rippleTC, twistedTC, 0.5));
}
