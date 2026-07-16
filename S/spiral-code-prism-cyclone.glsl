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
    float twist = log(radius + 0.035) * 3.5 - time_f * 0.28;
    vec2 q = rotation(twist) * p;
    float facet = sin(atan(q.y, q.x) * 9.0 - radius * 31.0);
    q += normalize(q + vec2(0.0001)) * facet * 0.008;
    vec2 uv = mirrorUV(0.5 + q / vec2(aspect, 1.0));
    vec2 tangent = normalize(vec2(-q.y, q.x) + vec2(0.0001)) / vec2(aspect, 1.0);
    float split = 0.0045 + 0.0025 * (0.5 + 0.5 * facet);

    vec3 result;
    result.r = texture(samp, mirrorUV(uv + tangent * split)).r;
    result.g = texture(samp, uv).g;
    result.b = texture(samp, mirrorUV(uv - tangent * split)).b;
    float shine = pow(max(facet, 0.0), 18.0);
    result += vec3(0.14, 0.18, 0.25) * shine;
    color = vec4(result, texture(samp, tc).a);
}
