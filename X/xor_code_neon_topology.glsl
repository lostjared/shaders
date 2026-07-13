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

vec3 palette(float t) {
    return 0.5 + 0.5 * cos(6.2831853 * (t + vec3(0.02, 0.36, 0.70)));
}

float luma(vec2 uv) {
    return dot(texture(samp, uv).rgb, vec3(0.299, 0.587, 0.114));
}

void main(void) {
    vec2 px = 1.5 / max(iResolution, vec2(1.0));
    float gx = luma(tc + vec2(px.x, 0.0)) - luma(tc - vec2(px.x, 0.0));
    float gy = luma(tc + vec2(0.0, px.y)) - luma(tc - vec2(0.0, px.y));
    float edge = length(vec2(gx, gy));
    vec2 tangent = normalize(vec2(-gy, gx) + vec2(0.0001));

    vec3 base = texture(samp, tc).rgb;
    vec3 echo = texture(samp, tc + tangent * (0.004 + edge * 0.04)).bgr;
    float bands = floor((luma(tc) + edge * 2.0 + time_f * 0.04) * 16.0) / 16.0;
    vec3 topo = palette(bands + atan(gy, gx) / 6.2831853);
    vec3 bits = xorColor(base, echo + topo * (0.5 + edge * 3.0));

    float line = smoothstep(0.03, 0.22, edge);
    vec3 result = mix(base, bits, 0.32 + line * 0.48);
    result += topo * pow(clamp(edge * 3.5, 0.0, 1.0), 1.5) * 0.7;
    result = pow(clamp(result, 0.0, 1.0), vec3(0.88));
    color = vec4(result, texture(samp, tc).a);
}
