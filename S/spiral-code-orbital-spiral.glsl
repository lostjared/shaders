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
    return 0.5 + 0.5 * cos(TAU * (t + vec3(0.02, 0.25, 0.58)));
}

void main(void) {
    vec2 size = vec2(textureSize(samp, 0));
    float aspect = size.x / max(size.y, 1.0);
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    float radius = length(p) + 0.0001;
    float angle = atan(p.y, p.x);
    float twist = log(radius + 0.03) * 3.0 - time_f * 0.38;
    vec2 q = rotation(twist) * p;
    vec3 source = texture(samp, mirrorUV(0.5 + q / vec2(aspect, 1.0))).rgb;

    vec3 orbitalGlow = vec3(0.0);
    for (int i = 0; i < 6; i++) {
        float index = float(i);
        float orbitRadius = 0.09 + index * 0.085;
        float orbitAngle = time_f * (0.16 + index * 0.025) + index * 1.7 + log(orbitRadius) * 2.2;
        vec2 body = vec2(cos(orbitAngle), sin(orbitAngle)) * orbitRadius;
        float distanceToBody = length(p - body);
        float glow = 0.00035 / (distanceToBody * distanceToBody + 0.0006);
        float trail =
            exp(-90.0 * abs(radius - orbitRadius)) * pow(0.5 + 0.5 * cos(angle - orbitAngle), 10.0);
        orbitalGlow += palette(index * 0.14 + time_f * 0.02) * (glow + trail * 0.18);
    }

    vec3 result = source * 0.90 + orbitalGlow * 0.18;
    result += palette(time_f * 0.03) * exp(-radius * 12.0) * 0.24;
    color = vec4(result, texture(samp, tc).a);
}
