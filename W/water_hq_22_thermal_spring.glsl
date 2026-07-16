#version 330 core
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;

float hash21(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
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
    float t = time_f * 0.20;
    vec2 p = tc * 5.0;
    float n = noise(p + vec2(noise(p - t), -t * 1.7));
    float n2 = noise(p * 1.9 + vec2(t * 1.4, n));
    vec2 haze = vec2(n - 0.5, n2 - 0.5) * 0.027 * (0.35 + 0.65 * tc.y);
    vec4 src = texture(samp, safeUV(tc + haze));
    float steam = smoothstep(0.58, 0.94, n) * smoothstep(0.15, 0.85, tc.y);
    vec3 rgb = mix(src.rgb, src.rgb * vec3(1.03, 0.97, 0.91), 0.22);
    rgb = mix(rgb, vec3(0.84, 0.91, 0.90), steam * 0.16);
    color = vec4(rgb, texture(samp, tc).a);
}
