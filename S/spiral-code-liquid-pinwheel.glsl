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
    float angle = atan(p.y, p.x);
    float blades = sin(angle * 7.0 - radius * 22.0 + time_f * 1.2);
    float twist = 1.35 * exp(-radius * 1.6) + blades * 0.13;
    vec2 q = rotation(twist + time_f * 0.12) * p;
    q += normalize(q + vec2(0.0001)) * sin(radius * 46.0 - time_f * 2.0) * 0.008;

    vec3 source = texture(samp, mirrorUV(0.5 + q / vec2(aspect, 1.0))).rgb;
    float sheen = pow(max(blades, 0.0), 12.0);
    vec3 result = source * vec3(0.92, 1.00, 1.05) + vec3(0.08, 0.23, 0.27) * sheen;
    color = vec4(result, texture(samp, tc).a);
}
