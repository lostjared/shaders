#version 330

in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform sampler1D spectrum;

// Three layered twists from low/mid/high bands composed sequentially.
vec2 twistOnce(vec2 uv, float strength, float t) {
    vec2 center = vec2(0.5);
    vec2 d = uv - center;
    float r = length(d);
    float a = strength * (r - 1.0) + t;
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c) * d + center;
}

void main(void) {
    float lo = texture(spectrum, 0.05).r;
    float md = texture(spectrum, 0.30).r;
    float hi = texture(spectrum, 0.70).r;

    vec2 uv = tc;
    uv = twistOnce(uv, 1.0 + lo * 5.0, time_f * 0.5);
    uv = twistOnce(uv, 1.0 + md * 4.0, -time_f * 0.7);
    uv = twistOnce(uv, 1.0 + hi * 3.0, time_f * 1.1);

    float ripple = sin(tc.x * 10.0 + time_f * 5.0) * 0.03;
    ripple += sin(tc.y * 10.0 + time_f * 5.0) * 0.03;
    vec2 rippleTC = tc + vec2(ripple);

    color = texture(samp, mix(rippleTC, uv, 0.5));
}
