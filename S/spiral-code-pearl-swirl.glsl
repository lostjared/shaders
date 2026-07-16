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

vec3 pearl(float t) {
    return 0.72 + 0.28 * cos(TAU * (t + vec3(0.00, 0.18, 0.42)));
}

void main(void) {
    vec2 size = vec2(textureSize(samp, 0));
    float aspect = size.x / max(size.y, 1.0);
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    float radius = length(p);
    float wave = sin(radius * 38.0 - atan(p.y, p.x) * 6.0 - time_f * 1.1);
    float twist = log(radius + 0.055) * 2.4 - time_f * 0.12 + wave * 0.06;
    vec2 q = rotation(twist) * p;
    q += normalize(q + vec2(0.0001)) * wave * 0.006;
    vec2 uv = mirrorUV(0.5 + q / vec2(aspect, 1.0));
    vec3 source = texture(samp, uv).rgb;

    float luster = pow(max(wave, 0.0), 14.0);
    float fresnel = pow(clamp(radius * 1.25, 0.0, 1.0), 2.5);
    vec3 result = mix(source, source * pearl(radius - time_f * 0.035), 0.35);
    result += pearl(wave * 0.12 + time_f * 0.03) * luster * 0.20;
    result = mix(result, result * vec3(0.92, 1.00, 1.07), fresnel * 0.14);
    color = vec4(result, texture(samp, tc).a);
}
