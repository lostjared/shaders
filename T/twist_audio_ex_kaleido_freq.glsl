#version 330

in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform sampler1D spectrum;

// Audio-driven kaleidoscopic mirroring on top of the twist.
void main(void) {
    float bass = texture(spectrum, 0.05).r;
    float mid  = texture(spectrum, 0.30).r;

    vec2 center = vec2(0.5);
    vec2 d = tc - center;
    float radius = length(d);
    float theta = atan(d.y, d.x);

    float slices = 4.0 + floor(mid * 12.0);
    float seg = 6.2831853 / slices;
    theta = abs(mod(theta, seg) - seg * 0.5);
    vec2 kd = vec2(cos(theta), sin(theta)) * radius;

    float twistStrength = 1.0 + bass * 6.0;
    float angle = twistStrength * (radius - 1.0) + time_f;
    float c = cos(angle), s = sin(angle);
    vec2 twistedTC = mat2(c, -s, s, c) * kd + center;

    float ripple = sin(tc.x * 10.0 + time_f * 5.0) * 0.03;
    ripple += sin(tc.y * 10.0 + time_f * 5.0) * 0.03;
    vec2 rippleTC = tc + vec2(ripple);

    color = texture(samp, mix(rippleTC, twistedTC, 0.5));
}
