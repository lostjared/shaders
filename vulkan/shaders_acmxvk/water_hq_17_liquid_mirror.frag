#version 450

layout(set = 0, binding = 1, std140) uniform SpriteExtended {
    vec4 mouse;
    vec4 u0;
    vec4 u1;
    vec4 u2;
    vec4 u3;
    vec4 custom_uniforms[16];
    vec4 audio_bands;
    vec4 audio_history;
} ext;
#define time_f ext.u2.y

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;


vec2 safeUV(vec2 p) {
    return 1.0 - abs(mod(p, 2.0) - 1.0);
}

void main(void) {
    float horizon = 0.50 + sin(tc.x * 4.0 + time_f * 0.25) * 0.012;
    float below = smoothstep(horizon - 0.01, horizon + 0.02, tc.y);
    vec2 reflected = vec2(tc.x, 2.0 * horizon - tc.y);
    float ripple = sin(tc.y * 48.0 + tc.x * 11.0 - time_f * 2.2) * 0.009;
    ripple += sin(tc.y * 83.0 - tc.x * 17.0 + time_f * 1.6) * 0.003;
    reflected.x += ripple * below;
    vec2 uv = mix(tc, reflected, below * 0.88);
    vec4 src = texture(samp, safeUV(uv));
    float glint = pow(max(0.0, sin(tc.y * 48.0 + tc.x * 11.0 - time_f * 2.2)), 20.0) * below;
    vec3 rgb = mix(src.rgb, src.rgb * vec3(0.76, 0.91, 1.02), below * 0.25) + vec3(0.20) * glint;
    color = vec4(rgb, texture(samp, tc).a);
}
