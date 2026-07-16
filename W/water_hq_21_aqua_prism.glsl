#version 330 core
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;

vec2 safeUV(vec2 p) {
    return 1.0 - abs(mod(p, 2.0) - 1.0);
}

void main(void) {
    float t = time_f * 0.75;
    float x = sin(tc.y * 18.0 + t) + 0.45 * sin((tc.x + tc.y) * 31.0 - t * 1.4);
    float y = sin(tc.x * 21.0 - t * 0.9) + 0.38 * sin((tc.x - tc.y) * 37.0 + t * 1.7);
    vec2 flow = vec2(x, y) * 0.010;
    vec2 dispersion = normalize(flow + vec2(1e-5)) * 0.0038;
    vec3 rgb;
    rgb.r = texture(samp, safeUV(tc + flow + dispersion)).r;
    rgb.g = texture(samp, safeUV(tc + flow)).g;
    rgb.b = texture(samp, safeUV(tc + flow - dispersion)).b;
    float pearl = pow(max(0.0, x * y * 0.25 + 0.5), 12.0);
    rgb = mix(rgb, rgb * vec3(0.90, 1.05, 1.12), 0.20) + vec3(0.08, 0.16, 0.20) * pearl;
    color = vec4(rgb, texture(samp, tc).a);
}
