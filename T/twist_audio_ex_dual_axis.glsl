#version 330

in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform sampler1D spectrum;

// Two independent shears per axis driven by two distinct frequency bands.
void main(void) {
    float lo = texture(spectrum, 0.08).r;
    float hi = texture(spectrum, 0.55).r;

    vec2 center = vec2(0.5);
    vec2 d = tc - center;
    float radius = length(d);

    float ripple = sin(tc.x * (8.0 + lo * 12.0) + time_f * 5.0) * (0.02 + hi * 0.05);
    ripple += sin(tc.y * (8.0 + hi * 12.0) + time_f * 5.0) * (0.02 + lo * 0.05);
    vec2 rippleTC = tc + vec2(ripple);

    float angleX = lo * 4.0 * (radius - 1.0) + time_f;
    float angleY = hi * 4.0 * (radius - 1.0) - time_f * 0.7;
    vec2 t = d;
    t.x = cos(angleX) * d.x - sin(angleX) * d.y;
    t.y = sin(angleY) * d.x + cos(angleY) * d.y;
    vec2 twistedTC = t + center;

    color = texture(samp, mix(rippleTC, twistedTC, 0.5));
}
