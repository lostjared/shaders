#version 330

in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform sampler1D spectrum;

// Logarithmic spiral zoom whose pitch is set by the spectrum's mid-band.
void main(void) {
    float mid = texture(spectrum, 0.30).r;
    float hi  = texture(spectrum, 0.65).r;

    vec2 center = vec2(0.5);
    vec2 d = tc - center;
    float r = length(d) + 1e-4;
    float a = atan(d.y, d.x);

    float pitch = 0.3 + mid * 1.2;
    float zoom  = 1.0 + hi * 0.4;
    float lr = log(r) - time_f * 0.3 * (1.0 + mid);
    a += pitch * lr;
    r = exp(lr) / zoom;

    vec2 twistedTC = center + r * vec2(cos(a), sin(a));

    float ripple = sin(tc.x * 10.0 + time_f * 5.0) * 0.03;
    ripple += sin(tc.y * 10.0 + time_f * 5.0) * 0.03;
    vec2 rippleTC = tc + vec2(ripple);

    color = texture(samp, mix(rippleTC, twistedTC, 0.5));
}
