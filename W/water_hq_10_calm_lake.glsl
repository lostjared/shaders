#version 330 core
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;

vec2 safeUV(vec2 p) {
    return 1.0 - abs(mod(p, 2.0) - 1.0);
}

void main(void) {
    float t = time_f * 0.32;
    float longWave = sin(tc.x * 14.0 + t) * 0.0045;
    float microWave = sin(tc.x * 47.0 - tc.y * 9.0 - t * 2.1) * 0.0018;
    microWave += sin(tc.x * 29.0 + tc.y * 13.0 + t * 1.4) * 0.0012;
    vec2 uv = safeUV(tc + vec2(longWave + microWave, microWave * 0.45));
    vec4 sharp = texture(samp, uv);
    vec3 soft = (texture(samp, safeUV(uv + vec2(0.0025, 0))).rgb +
                 texture(samp, safeUV(uv - vec2(0.0025, 0))).rgb) *
                0.5;
    float shimmer = pow(max(0.0, sin(tc.x * 47.0 - t * 2.1)), 24.0);
    vec3 rgb = mix(sharp.rgb, soft, 0.18) * vec3(0.94, 0.99, 1.02);
    rgb += vec3(0.14, 0.19, 0.20) * shimmer * 0.18;
    color = vec4(rgb, texture(samp, tc).a);
}
