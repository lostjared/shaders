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

vec3 palette(float t) {
    return 0.5 + 0.5 * cos(TAU * (t + vec3(0.07, 0.36, 0.68)));
}

void main(void) {
    vec2 size = vec2(textureSize(samp, 0));
    float aspect = size.x / max(size.y, 1.0);
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    float originalRadius = length(p);
    float orbit = 0.0;

    for (int i = 0; i < 5; i++) {
        float index = float(i);
        float radius = length(p) + 0.02;
        p = rotation(log(radius) * 0.55 + time_f * 0.025 + index * 0.41) * p;
        p = abs(p) - vec2(0.22, 0.16);
        orbit += exp(-8.0 * abs(length(p) - 0.18));
        p *= 1.32;
    }

    vec2 uv = mirrorUV(0.5 + p * 0.22 / vec2(aspect, 1.0));
    vec3 source = texture(samp, uv).rgb;
    float lines = clamp(orbit / 5.0, 0.0, 1.0);
    vec3 result = mix(source, source * palette(originalRadius + time_f * 0.03), 0.30);
    result += palette(lines + originalRadius) * lines * 0.22;
    color = vec4(result, texture(samp, tc).a);
}
