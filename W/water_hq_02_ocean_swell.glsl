#version 330 core
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;

vec2 safeUV(vec2 p) {
    return 1.0 - abs(mod(p, 2.0) - 1.0);
}

void main(void) {
    float t = time_f * 0.55;
    vec2 p = tc * 6.2831853;
    float a = sin(p.x * 1.25 + p.y * 0.45 - t * 2.1);
    float b = sin(p.x * 0.55 - p.y * 1.1 + t * 1.35);
    float c = sin(p.x * 2.2 + p.y * 0.2 - t * 2.8);
    vec2 flow = vec2(a + 0.35 * c, b - 0.25 * c) * 0.014;
    vec4 src = texture(samp, safeUV(tc + flow));
    float crest = pow(0.5 + 0.5 * (a * 0.62 + b * 0.26 + c * 0.12), 5.0);
    vec3 ocean = mix(src.rgb, src.rgb * vec3(0.82, 0.95, 1.06), 0.24);
    ocean += vec3(0.12, 0.23, 0.28) * crest;
    color = vec4(ocean, texture(samp, tc).a);
}
