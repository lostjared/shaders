#version 330 core

in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

vec2 rotate2(vec2 p, float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c) * p;
}

void main(void) {
    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 ar = vec2(aspect, 1.0);
    vec2 p = (tc - 0.5) * ar;
    float originalR = length(p) + 0.001;
    float glow = 0.0;
    for (int i = 0; i < 6; ++i) {
        float fi = float(i);
        float r = length(p) + 0.035;
        float a = 0.32 + 0.17 * sin(time_f * 0.8 + fi) + 0.22 / r;
        p = rotate2(p, a);
        p = abs(p) - vec2(0.31, 0.22);
        p *= 1.22;
        glow += exp(-length(p) * 4.5) / 6.0;
    }
    float a = atan(p.y, p.x) + 1.1 / originalR + time_f;
    float r = length(p) + sin(originalR * 72.0 - time_f * 11.0) * 0.04;
    vec2 uv = fract(vec2(cos(a), sin(a)) * r / ar + 0.5);
    vec4 tex = texture(samp, uv);
    vec3 rgb = tex.rgb * (0.72 + glow * 1.5);
    rgb = mix(rgb, rgb.bgr, 0.25 * sin(originalR * 44.0 - time_f * 6.0) + 0.25);
    color = vec4(rgb, tex.a);
}
