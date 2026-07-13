#version 330 core

in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

uvec3 bytes(vec3 c) {
    return uvec3(clamp(floor(c * 255.0 + 0.5), 0.0, 255.0));
}

uvec3 rotateBits(uvec3 v, uint amount) {
    return ((v << amount) | (v >> (8u - amount))) & uvec3(255u);
}

vec3 palette(float t) {
    return 0.5 + 0.5 * cos(6.2831853 * (t + vec3(0.00, 0.35, 0.69)));
}

void main(void) {
    vec2 p = tc - 0.5;
    float radius = length(p);
    float angle = atan(p.y, p.x);
    vec2 uvA = tc + vec2(sin(angle * 5.0 + time_f), cos(radius * 27.0 - time_f)) * 0.012;
    vec2 uvB = tc.yx + vec2(cos(angle * 7.0), sin(radius * 31.0)) * 0.009;

    vec3 a = texture(samp, uvA).rgb;
    vec3 b = texture(samp, uvB).bgr;
    uvec3 ua = bytes(a);
    uvec3 ub = bytes(b);
    uint phase = 1u + uint(mod(floor(time_f * 0.7 + radius * 8.0), 6.0));
    uvec3 quantum = rotateBits(ua, phase) ^ rotateBits(ub, 7u - phase);
    quantum ^= uvec3(0x55u, 0xAAu, 0x33u);
    vec3 bits = vec3(quantum & uvec3(255u)) / 255.0;

    vec3 tint = palette(float(phase) / 7.0 + angle / 6.2831853 + time_f * 0.02);
    float pulse = 0.5 + 0.5 * sin(radius * 52.0 - time_f * 5.0);
    vec3 result = mix(a, bits, 0.5 + pulse * 0.2);
    result = mix(result, sqrt(max(result, 0.0)) * tint, 0.38);
    result += tint * pow(pulse, 9.0) * 0.22;
    color = vec4(clamp(result, 0.0, 1.0), texture(samp, tc).a);
}
