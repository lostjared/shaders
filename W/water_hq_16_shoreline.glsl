#version 330 core
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;

vec2 safeUV(vec2 p) {
    return 1.0 - abs(mod(p, 2.0) - 1.0);
}

void main(void) {
    float bend = sin(tc.x * 9.0 + time_f * 0.35) * 0.035 + sin(tc.x * 21.0 - time_f * 0.22) * 0.012;
    float phase = (tc.y + bend) * 18.0 - time_f * 1.65;
    float wave = sin(phase) + 0.35 * sin(phase * 2.1 + 1.2);
    float push = wave * 0.009 * smoothstep(0.05, 0.75, tc.y);
    vec4 src = texture(samp, safeUV(tc + vec2(push * 0.35, push)));
    float breaker = pow(clamp(wave * 0.5 + 0.5, 0.0, 1.0), 14.0);
    breaker *= smoothstep(0.12, 0.40, tc.y) * (1.0 - smoothstep(0.58, 0.92, tc.y));
    float wet = 1.0 - smoothstep(0.04, 0.42, tc.y + bend * 0.4);
    vec3 rgb = src.rgb * (1.0 - wet * 0.08);
    rgb = mix(rgb, vec3(0.78, 0.92, 0.93), breaker * 0.36);
    color = vec4(rgb, texture(samp, tc).a);
}
