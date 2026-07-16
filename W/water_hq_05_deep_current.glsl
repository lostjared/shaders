#version 330 core
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;

float hash21(vec2 p) {
    return fract(sin(dot(p, vec2(41.0, 289.0))) * 45758.5453);
}
float noise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash21(i), hash21(i + vec2(1, 0)), f.x),
               mix(hash21(i + vec2(0, 1)), hash21(i + vec2(1, 1)), f.x), f.y);
}
float fbm(vec2 p) {
    float v = 0.0;
    v += noise(p) * 0.57;
    p = p * 2.03 + 7.1;
    v += noise(p) * 0.28;
    p = p * 2.07 + 3.7;
    v += noise(p) * 0.15;
    return v;
}
vec2 safeUV(vec2 p) {
    return 1.0 - abs(mod(p, 2.0) - 1.0);
}

void main(void) {
    float t = time_f * 0.18;
    float e = 0.012;
    vec2 p = tc * vec2(4.0, 6.0) + vec2(t, -t * 0.4);
    float h = fbm(p);
    vec2 g = vec2(fbm(p + vec2(e, 0)) - h, fbm(p + vec2(0, e)) - h) / e;
    vec4 src = texture(samp, safeUV(tc + vec2(g.y, -g.x) * 0.024));
    float depth = smoothstep(0.0, 1.0, tc.y);
    vec3 rgb = mix(src.rgb, src.rgb * vec3(0.68, 0.86, 0.94), 0.28 + depth * 0.16);
    color = vec4(rgb, texture(samp, tc).a);
}
