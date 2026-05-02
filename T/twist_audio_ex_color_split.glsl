#version 330

in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform sampler1D spectrum;

// RGB channels split to neighboring spectrum bands and twist with their own strengths.
vec2 twistAt(vec2 uv, float strength, float bias) {
    vec2 center = vec2(0.5);
    vec2 d = uv - center;
    float r = length(d);
    float a = strength * (r - 1.0) + time_f + bias;
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c) * d + center;
}

void main(void) {
    float r = texture(spectrum, 0.10).r;
    float g = texture(spectrum, 0.40).r;
    float b = texture(spectrum, 0.75).r;

    vec2 tR = twistAt(tc, 1.0 + r * 4.0, 0.0);
    vec2 tG = twistAt(tc, 1.0 + g * 4.0, 0.7);
    vec2 tB = twistAt(tc, 1.0 + b * 4.0, -0.7);

    vec3 outc;
    outc.r = texture(samp, tR).r;
    outc.g = texture(samp, tG).g;
    outc.b = texture(samp, tB).b;
    color = vec4(outc, 1.0);
}
