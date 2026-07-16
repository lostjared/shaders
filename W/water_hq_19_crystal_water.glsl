#version 330 core
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;

float hash21(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
vec2 hash22(vec2 p) {
    return vec2(hash21(p), hash21(p + 19.19));
}
vec2 safeUV(vec2 p) {
    return 1.0 - abs(mod(p, 2.0) - 1.0);
}

void main(void) {
    vec2 p = tc * 9.0, id = floor(p), f = fract(p);
    float best = 10.0, second = 10.0;
    vec2 nearest = vec2(0.0);
    for (int y = -1; y <= 1; y++)
        for (int x = -1; x <= 1; x++) {
            vec2 g = vec2(x, y), point = g + hash22(id + g);
            point += 0.10 * sin(time_f * 0.45 + 6.283 * hash22(id + g));
            float d = length(f - point);
            if (d < best) {
                second = best;
                best = d;
                nearest = f - point;
            } else if (d < second) {
                second = d;
            }
        }
    float edge = 1.0 - smoothstep(0.0, 0.10, second - best);
    vec2 uv = safeUV(tc + normalize(nearest + vec2(1e-5)) * (0.008 + best * 0.006));
    vec4 src = texture(samp, uv);
    vec3 rgb = src.rgb * vec3(0.91, 1.00, 1.04) + vec3(0.18, 0.31, 0.35) * edge * 0.38;
    color = vec4(rgb, texture(samp, tc).a);
}
