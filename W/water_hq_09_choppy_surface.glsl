#version 330 core
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;

vec2 safeUV(vec2 p) {
    return 1.0 - abs(mod(p, 2.0) - 1.0);
}
float wave(vec2 p, vec2 d, float f, float s) {
    return sin(dot(p, normalize(d)) * f + time_f * s);
}

void main(void) {
    vec2 p = tc * 6.2831853;
    float w1 = wave(p, vec2(1.0, 0.35), 2.3, -2.0);
    float w2 = wave(p, vec2(-0.4, 1.0), 3.8, 2.7);
    float w3 = wave(p, vec2(0.8, -0.6), 6.1, -3.4);
    vec2 disp = vec2(w1 + 0.45 * w3, w2 - 0.35 * w3) * 0.012;
    vec4 src = texture(samp, safeUV(tc + disp));
    float peak = smoothstep(0.58, 1.0, w1 * 0.48 + w2 * 0.32 + w3 * 0.20);
    float trough = 1.0 - smoothstep(-0.75, 0.25, w1 * 0.6 + w2 * 0.4);
    vec3 rgb = src.rgb * (1.0 - trough * 0.10) + vec3(0.55, 0.78, 0.84) * peak * 0.26;
    color = vec4(rgb, texture(samp, tc).a);
}
