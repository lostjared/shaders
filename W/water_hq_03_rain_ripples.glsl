#version 330 core
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;

float hash21(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
vec2 safeUV(vec2 p) {
    return 1.0 - abs(mod(p, 2.0) - 1.0);
}

vec2 rainLayer(vec2 uv, float scale, float seed) {
    vec2 p = uv * scale;
    vec2 id = floor(p);
    vec2 f = fract(p) - 0.5;
    float rnd = hash21(id + seed);
    vec2 center = vec2(hash21(id + seed + 3.1), hash21(id + seed + 8.7)) - 0.5;
    vec2 d = f - center * 0.65;
    float age = fract(time_f * (0.28 + rnd * 0.18) + rnd);
    float r = length(d);
    float ring = exp(-90.0 * abs(r - age * 0.48)) * (1.0 - age);
    return normalize(d + vec2(1e-5)) * ring / scale;
}

void main(void) {
    vec2 ripple = rainLayer(tc, 7.0, 1.0) + rainLayer(tc + 0.17, 11.0, 19.0);
    vec4 src = texture(samp, safeUV(tc + ripple * 0.72));
    float sparkle = clamp(length(ripple) * 36.0, 0.0, 1.0);
    color = vec4(src.rgb + vec3(0.10, 0.15, 0.18) * sparkle, texture(samp, tc).a);
}
