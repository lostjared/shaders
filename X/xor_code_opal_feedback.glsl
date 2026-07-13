#version 330 core

in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

uvec3 bytes(vec3 c) {
    return uvec3(clamp(floor(c * 255.0 + 0.5), 0.0, 255.0));
}

vec3 xorColor(vec3 a, vec3 b) {
    return vec3((bytes(a) ^ bytes(b)) & uvec3(255u)) / 255.0;
}

vec3 film(float t) {
    return 0.52 + 0.48 * cos(6.2831853 * (t + vec3(0.02, 0.28, 0.64)));
}

vec2 rotateAround(vec2 uv, float angle, float scale) {
    float c = cos(angle);
    float s = sin(angle);
    return mat2(c, -s, s, c) * (uv - 0.5) * scale + 0.5;
}

void main(void) {
    vec2 p = tc - 0.5;
    float radius = length(p);
    float angle = 0.08 * sin(time_f * 0.7 + radius * 12.0);
    vec2 uv0 = rotateAround(tc, angle, 1.015);
    vec2 uv1 = rotateAround(tc, -angle * 1.7, 0.975);
    vec2 uv2 = rotateAround(tc, angle * 2.3, 1.045);

    vec3 a = texture(samp, uv0).rgb;
    vec3 b = texture(samp, uv1).gbr;
    vec3 c = texture(samp, uv2).brg;
    vec3 stageA = xorColor(a, b * (1.3 + 0.4 * sin(time_f)));
    vec3 stageB = xorColor(stageA, c + film(radius + time_f * 0.025) * 0.35);

    float interference = sin(radius * 70.0 - time_f * 6.0 + atan(p.y, p.x) * 4.0);
    vec3 iridescence = film(radius * 1.8 + interference * 0.12 + time_f * 0.02);
    vec3 result = mix(a, stageB, 0.48 + 0.18 * interference);
    result = mix(result, result * iridescence * 1.4, 0.42);
    result += iridescence * pow(0.5 + 0.5 * interference, 10.0) * 0.3;
    color = vec4(clamp(result, 0.0, 1.0), texture(samp, tc).a);
}
