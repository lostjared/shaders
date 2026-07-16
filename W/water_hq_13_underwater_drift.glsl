#version 330 core
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;

float hash21(vec2 p) {
    return fract(sin(dot(p, vec2(123.4, 357.8))) * 43758.5453);
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
    float t = time_f * 0.16;
    float n1 = noise(tc * 5.0 + vec2(t, -t * 0.6));
    float n2 = noise(tc * 9.0 + vec2(-t * 1.3, t));
    vec2 drift = vec2(n1 - 0.5, n2 - 0.5) * 0.025;
    vec4 src = texture(samp, safeUV(tc + drift));
    float shafts = pow(max(0.0, sin(tc.x * 17.0 + tc.y * 4.0 - time_f * 0.35 + n1 * 3.0)), 6.0);
    float depth = smoothstep(0.0, 1.0, tc.y);
    vec3 rgb = src.rgb * mix(vec3(0.72, 0.92, 1.0), vec3(0.54, 0.78, 0.91), depth * 0.45);
    rgb += vec3(0.06, 0.18, 0.22) * shafts * (1.0 - depth) * 0.30;
    color = vec4(rgb, texture(samp, tc).a);
}
