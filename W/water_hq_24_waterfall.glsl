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
    float t = time_f * 0.75;
    float lane = noise(vec2(tc.x * 12.0, tc.y * 3.0 - t));
    float streak = noise(vec2(tc.x * 31.0 + lane * 4.0, tc.y * 8.0 - t * 3.2));
    vec2 flow = vec2((lane - 0.5) * 0.018, (streak - 0.5) * 0.015);
    vec4 src = texture(samp, safeUV(tc + flow));
    float white = pow(smoothstep(0.55, 1.0, streak), 3.0);
    float spray = smoothstep(0.75, 1.0, noise(vec2(tc.x * 19.0 + t, tc.y * 11.0 + t))) *
                  (1.0 - smoothstep(0.08, 0.28, tc.y));
    vec3 rgb = src.rgb * vec3(0.84, 0.96, 1.02);
    rgb = mix(rgb, vec3(0.80, 0.94, 0.97), clamp(white * 0.32 + spray * 0.38, 0.0, 0.55));
    color = vec4(rgb, texture(samp, tc).a);
}
