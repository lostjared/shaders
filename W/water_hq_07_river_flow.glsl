#version 330 core
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;

float hash21(vec2 p) {
    return fract(sin(dot(p, vec2(91.7, 263.3))) * 43758.5453);
}
float noise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash21(i), hash21(i + vec2(1, 0)), f.x),
               mix(hash21(i + vec2(0, 1)), hash21(i + vec2(1, 1)), f.x), f.y);
}
vec2 safeUV(vec2 p) {
    return 1.0 - abs(mod(p, 2.0) - 1.0);
}

void main(void) {
    float t = time_f * 0.45;
    vec2 p = tc * vec2(3.0, 10.0);
    float lane = noise(vec2(p.y * 0.35 - t, p.x + noise(p - t) * 1.7));
    float filament = sin(p.y * 2.8 - t * 5.0 + lane * 6.0);
    vec2 flow = vec2((lane - 0.5) * 0.035, filament * 0.006);
    vec4 src = texture(samp, safeUV(tc + flow));
    float sheen = pow(max(filament, 0.0), 8.0) * (0.35 + 0.65 * lane);
    vec3 rgb = src.rgb * vec3(0.90, 0.98, 1.02) + vec3(0.08, 0.16, 0.18) * sheen;
    color = vec4(rgb, texture(samp, tc).a);
}
