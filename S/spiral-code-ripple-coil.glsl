#version 330 core

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float time_f;

mat2 rotation(float angle) {
    float sine = sin(angle);
    float cosine = cos(angle);
    return mat2(cosine, -sine, sine, cosine);
}

vec2 mirrorUV(vec2 uv) {
    return 1.0 - abs(mod(uv, 2.0) - 1.0);
}

void main(void) {
    vec2 size = vec2(textureSize(samp, 0));
    float aspect = size.x / max(size.y, 1.0);
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    float radius = length(p);
    float ripple = sin(radius * 64.0 - time_f * 2.8);
    float twist = log(radius + 0.05) * 2.2 + ripple * 0.10 - time_f * 0.18;
    vec2 q = rotation(twist) * p;
    q += normalize(q + vec2(0.0001)) * ripple * 0.010;

    vec3 source = texture(samp, mirrorUV(0.5 + q / vec2(aspect, 1.0))).rgb;
    float crest = pow(max(ripple, 0.0), 14.0);
    float coil = pow(0.5 + 0.5 * sin(atan(q.y, q.x) * 5.0 - radius * 28.0), 8.0);
    vec3 result = source * vec3(0.91, 0.98, 1.04);
    result += vec3(0.10, 0.24, 0.30) * crest * (0.35 + coil * 0.65);
    color = vec4(result, texture(samp, tc).a);
}
