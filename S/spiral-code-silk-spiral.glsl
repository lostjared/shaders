#version 330 core

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float time_f;

vec2 mirrorUV(vec2 uv) {
    return 1.0 - abs(mod(uv, 2.0) - 1.0);
}

mat2 rotation(float angle) {
    float sine = sin(angle);
    float cosine = cos(angle);
    return mat2(cosine, -sine, sine, cosine);
}

void main(void) {
    vec2 size = vec2(textureSize(samp, 0));
    float aspect = size.x / max(size.y, 1.0);
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    float radius = length(p);
    float angle = atan(p.y, p.x);
    float ribbonA = sin(angle * 5.0 - radius * 30.0 + time_f * 0.75);
    float ribbonB = sin(angle * 8.0 + radius * 19.0 - time_f * 0.52);
    float twist = log(radius + 0.06) * 2.0 + ribbonA * 0.07 + ribbonB * 0.035;
    vec2 q = rotation(twist - time_f * 0.10) * p;
    q += vec2(ribbonA, ribbonB) * 0.006;

    vec2 uv = mirrorUV(0.5 + q / vec2(aspect, 1.0));
    vec3 sharp = texture(samp, uv).rgb;
    vec3 soft = (texture(samp, mirrorUV(uv + vec2(0.0025, 0.0))).rgb +
                 texture(samp, mirrorUV(uv - vec2(0.0025, 0.0))).rgb) *
                0.5;
    float sheen = pow(max(ribbonA * 0.72 + ribbonB * 0.28, 0.0), 12.0);
    vec3 result = mix(sharp, soft, 0.22) * vec3(0.96, 1.0, 1.04);
    result += vec3(0.13, 0.20, 0.24) * sheen * 0.30;
    color = vec4(result, texture(samp, tc).a);
}
