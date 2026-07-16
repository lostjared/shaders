#version 330 core

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float time_f;

const float TAU = 6.28318530718;

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
    float radius = length(p) + 0.002;
    float depth = fract(-log(radius) * 0.48 + time_f * 0.16);
    float twist = depth * TAU * 0.72 - time_f * TAU * 0.045;
    float tunnelRadius = mix(0.06, 0.72, depth);
    vec2 direction = p / radius;
    vec2 tunnelPoint = rotation(twist) * direction * tunnelRadius;
    vec2 uv = mirrorUV(0.5 + tunnelPoint / vec2(aspect, 1.0));

    vec2 tangent = normalize(vec2(-p.y, p.x) + vec2(0.0001)) / vec2(aspect, 1.0);
    float split = 0.006 + depth * 0.004;
    vec3 result;
    result.r = texture(samp, mirrorUV(uv + tangent * split)).r;
    result.g = texture(samp, uv).g;
    result.b = texture(samp, mirrorUV(uv - tangent * split)).b;
    float ring = pow(0.5 + 0.5 * sin(depth * TAU * 7.0), 16.0);
    result += vec3(0.14, 0.20, 0.26) * ring * (1.0 - radius) * 0.30;
    color = vec4(result, texture(samp, tc).a);
}
