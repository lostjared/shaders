#version 330 core

in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

float hash21(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

uvec3 bytes(vec3 c) {
    return uvec3(clamp(floor(c * 255.0 + 0.5), 0.0, 255.0));
}

vec3 xorColor(vec3 a, vec3 b) {
    return vec3((bytes(a) ^ bytes(b)) & uvec3(255u)) / 255.0;
}

vec3 palette(float t) {
    return 0.5 + 0.5 * cos(6.2831853 * (t + vec3(0.05, 0.39, 0.72)));
}

void main(void) {
    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    vec2 gridUV = p * 14.0;
    vec2 cell = fract(gridUV) - 0.5;
    vec2 id = floor(gridUV);
    float seed = hash21(id);

    float horizontal = 1.0 - smoothstep(0.035, 0.09, abs(cell.y));
    float vertical = 1.0 - smoothstep(0.035, 0.09, abs(cell.x));
    float selector = step(0.5, seed);
    float trace = mix(horizontal, vertical, selector);
    float node = 1.0 - smoothstep(0.09, 0.16, length(cell));
    float circuit = max(trace * step(0.24, abs(cell.x + cell.y)), node);

    vec2 refractUV = tc + normalize(cell + vec2(0.0001)) * circuit * 0.008;
    vec3 base = texture(samp, refractUV).rgb;
    vec3 echo = texture(samp, tc + vec2(cell.y, -cell.x) * 0.018).gbr;
    vec3 bits = xorColor(base, echo + vec3(seed, 1.0 - seed, fract(seed * 7.0)));
    vec3 tint = palette(seed + time_f * 0.025);

    vec3 result = mix(base, bits, 0.28 + circuit * 0.48);
    result += tint * circuit * (0.25 + 0.25 * sin(time_f * 4.0 + seed * 20.0));
    color = vec4(clamp(result, 0.0, 1.0), texture(samp, refractUV).a);
}
