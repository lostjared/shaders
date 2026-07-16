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

float hash21(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec3 palette(float t) {
    return 0.5 + 0.5 * cos(TAU * (t + vec3(0.08, 0.35, 0.68)));
}

vec2 mirrorUV(vec2 uv) {
    return 1.0 - abs(mod(uv, 2.0) - 1.0);
}

void main(void) {
    vec2 size = vec2(textureSize(samp, 0));
    float aspect = size.x / max(size.y, 1.0);
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    float radius = length(p);
    float twist = log(radius + 0.025) * 4.0 - time_f * 0.7;
    vec2 q = rotation(twist) * p;
    vec3 source = texture(samp, mirrorUV(0.5 + q / vec2(aspect, 1.0))).rgb;

    vec3 dust = vec3(0.0);
    for (int i = 0; i < 12; i++) {
        float index = float(i);
        float orbitRadius = 0.07 + hash21(vec2(index, 1.0)) * 0.55;
        float speed = 0.18 + hash21(vec2(index, 2.0)) * 0.45;
        float orbit = time_f * speed + hash21(vec2(index, 3.0)) * TAU;
        orbit += log(orbitRadius + 0.05) * 3.2;
        vec2 starPosition = vec2(cos(orbit), sin(orbit)) * orbitRadius;
        float distanceToStar = length(p - starPosition);
        float sparkle = 0.00014 / (distanceToStar * distanceToStar + 0.00025);
        dust += palette(index * 0.09 + time_f * 0.03) * sparkle;
    }

    vec3 result = source * 0.90 + dust * 0.18;
    result += palette(time_f * 0.04) * exp(-radius * 10.0) * 0.28;
    color = vec4(result, texture(samp, tc).a);
}
