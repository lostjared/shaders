#version 330 core
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;

vec2 safeUV(vec2 p) {
    return 1.0 - abs(mod(p, 2.0) - 1.0);
}

void main(void) {
    vec2 p = (tc - 0.5) * 8.0;
    vec2 d1 = normalize(vec2(1.0, 0.72));
    vec2 d2 = normalize(vec2(-0.84, 1.0));
    float a = sin(dot(p, d1) * 4.1 - time_f * 2.0);
    float b = sin(dot(p, d2) * 5.3 + time_f * 2.35);
    float interference = a * b;
    vec2 offset = (d1 * a + d2 * b) * 0.012 + vec2(d1.y, -d1.x) * interference * 0.004;
    vec4 src = texture(samp, safeUV(tc + offset));
    float crest = pow(clamp(interference * 0.5 + 0.5, 0.0, 1.0), 10.0);
    vec3 rgb = src.rgb * (0.96 + crest * 0.08) + vec3(0.12, 0.25, 0.30) * crest * 0.24;
    color = vec4(rgb, texture(samp, tc).a);
}
