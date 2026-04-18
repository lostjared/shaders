#version 330 core
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform float amp;
uniform float amp_low;
uniform float amp_mid;
uniform float amp_high;
uniform float amp_peak;
uniform float amp_smooth;

vec2 mirror(vec2 uv) {
    return abs(mod(uv, 2.0) - 1.0);
}

mat2 rot(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c);
}

void main(void) {
    float aLow = clamp(amp_low, 0.0, 1.0);
    float aMid = clamp(amp_mid, 0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float t = time_f;
    vec2 uv = 1.0 - abs(1.0 - 2.0 * tc);
    vec2 p = uv - 0.5;
    for (int i = 0; i < 5; i++) {
        float fi = float(i);
        p = abs(p) - (0.2 + 0.05 * sin(t * 0.5 + fi) * aLow);
        p = rot(t * 0.15 + fi * 0.7 + aMid * 0.3) * p;
    }
    uv = mirror(p + 0.5);
    vec3 col;
    float off = 0.003 + 0.008 * aHigh;
    col.r = texture(samp, uv + vec2(off, 0.0)).r;
    col.g = texture(samp, uv).g;
    col.b = texture(samp, uv - vec2(off, 0.0)).b;
    col *= 1.0 + amp_peak * 0.5;
    float glow = exp(-length(p) * 4.0) * amp_smooth * 0.4;
    col += glow * vec3(1.0, 0.4, 0.8);
    color = vec4(col, 1.0);
}
