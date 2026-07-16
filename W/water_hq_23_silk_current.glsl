#version 330 core
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;

vec2 safeUV(vec2 p) {
    return 1.0 - abs(mod(p, 2.0) - 1.0);
}

void main(void) {
    float t = time_f * 0.38;
    float ribbon1 = sin(tc.y * 12.0 + sin(tc.x * 7.0 - t) * 1.8 + t);
    float ribbon2 = sin(tc.y * 25.0 - t * 1.7 + sin(tc.x * 13.0 + t) * 1.2);
    float ribbon3 = sin((tc.x + tc.y) * 39.0 + t * 2.1);
    vec2 flow = vec2(ribbon1 * 0.012 + ribbon2 * 0.005, ribbon3 * 0.003);
    vec4 a = texture(samp, safeUV(tc + flow));
    vec4 b = texture(samp, safeUV(tc + flow * 0.45 + vec2(0.0025, 0.0)));
    float sheen = pow(max(0.0, ribbon1 * 0.65 + ribbon2 * 0.25 + ribbon3 * 0.10), 9.0);
    vec3 rgb =
        mix(a.rgb, b.rgb, 0.22) * vec3(0.94, 1.0, 1.04) + vec3(0.10, 0.20, 0.23) * sheen * 0.24;
    color = vec4(rgb, texture(samp, tc).a);
}
