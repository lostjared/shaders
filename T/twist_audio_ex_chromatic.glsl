#version 330

in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform sampler1D spectrum;

// Per-channel twist offsets create chromatic aberration tied to spectrum bands.
vec2 twistAt(vec2 uv, float strength) {
    vec2 center = vec2(0.5);
    vec2 d = uv - center;
    float r = length(d);
    float a = strength * (r - 1.0) + time_f;
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c) * d + center;
}

void main(void) {
    float r = texture(spectrum, 0.05).r;
    float g = texture(spectrum, 0.30).r;
    float b = texture(spectrum, 0.65).r;

    float ripple = sin(tc.x * 10.0 + time_f * 5.0) * 0.03;
    ripple += sin(tc.y * 10.0 + time_f * 5.0) * 0.03;
    vec2 rippleTC = tc + vec2(ripple);

    vec2 tR = twistAt(tc, 1.0 + r * 5.0);
    vec2 tG = twistAt(tc, 1.0 + g * 5.0);
    vec2 tB = twistAt(tc, 1.0 + b * 5.0);

    color.r = texture(samp, mix(rippleTC, tR, 0.5)).r;
    color.g = texture(samp, mix(rippleTC, tG, 0.5)).g;
    color.b = texture(samp, mix(rippleTC, tB, 0.5)).b;
    color.a = 1.0;
}
