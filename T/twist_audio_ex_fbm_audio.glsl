#version 330

in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform sampler1D spectrum;

// Twist driven by a noise-blended spectrum sample for organic motion.
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
float noise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    float a = hash(i), b = hash(i + vec2(1, 0));
    float c = hash(i + vec2(0, 1)), d = hash(i + vec2(1, 1));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

void main(void) {
    vec2 center = vec2(0.5);
    vec2 d = tc - center;
    float radius = length(d);

    float n = noise(tc * 4.0 + time_f * 0.5);
    float e = texture(spectrum, n).r;

    float twistStrength = 0.5 + e * 6.0;
    float angle = twistStrength * (radius - 1.0) + time_f + n;
    float c = cos(angle), s = sin(angle);
    vec2 twistedTC = mat2(c, -s, s, c) * d + center;

    float ripple = sin(tc.x * 10.0 + time_f * 5.0) * (0.02 + e * 0.05);
    ripple += sin(tc.y * 10.0 + time_f * 5.0) * (0.02 + e * 0.05);
    vec2 rippleTC = tc + vec2(ripple);

    color = texture(samp, mix(rippleTC, twistedTC, 0.5));
}
