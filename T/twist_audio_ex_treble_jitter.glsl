#version 330

in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform sampler1D spectrum;

// Treble injects high-frequency jitter into the twist angle.
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void main(void) {
    float treble = texture(spectrum, 0.62).r;
    float air    = texture(spectrum, 0.85).r;

    vec2 center = vec2(0.5);
    float radius = length(tc - center);

    float ripple = sin(tc.x * 10.0 + time_f * 5.0) * 0.03;
    ripple += sin(tc.y * 10.0 + time_f * 5.0) * 0.03;
    vec2 rippleTC = tc + vec2(ripple);

    float jitter = (hash(floor(tc * 256.0) + floor(time_f * 30.0)) - 0.5) * treble * 3.0;
    float angle = (1.0 + air * 2.0) * (radius - 1.0) + time_f + jitter;
    float c = cos(angle), s = sin(angle);
    vec2 twistedTC = mat2(c, -s, s, c) * (tc - center) + center;

    color = texture(samp, mix(rippleTC, twistedTC, 0.5));
}
