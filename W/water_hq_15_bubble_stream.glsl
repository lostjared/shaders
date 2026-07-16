#version 330 core
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;

float hash11(float p) {
    return fract(sin(p * 127.1) * 43758.5453);
}
vec2 safeUV(vec2 p) {
    return 1.0 - abs(mod(p, 2.0) - 1.0);
}

void main(void) {
    vec2 warp = vec2(0.0);
    float rim = 0.0;
    for (int i = 0; i < 7; i++) {
        float fi = float(i);
        float size = mix(0.025, 0.075, hash11(fi + 2.0));
        vec2 center = vec2(0.12 + 0.76 * hash11(fi + 8.0),
                           fract(hash11(fi + 4.0) + time_f * (0.035 + 0.018 * hash11(fi))));
        center.x += sin(time_f * 0.7 + fi * 2.3) * 0.025;
        vec2 d = tc - center;
        float r = length(d);
        float body = 1.0 - smoothstep(size * 0.82, size, r);
        warp += normalize(d + vec2(1e-5)) * body * (size - r) * 0.24;
        rim += smoothstep(size * 0.68, size * 0.88, r) * (1.0 - smoothstep(size * 0.88, size, r));
    }
    vec4 src = texture(samp, safeUV(tc + warp));
    vec3 rgb = src.rgb + vec3(0.18, 0.29, 0.34) * clamp(rim, 0.0, 1.0) * 0.45;
    color = vec4(rgb, texture(samp, tc).a);
}
