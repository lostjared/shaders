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
    return 0.54 + 0.46 * cos(6.2831853 * (t + vec3(0.02, 0.34, 0.68)));
}

vec3 gaussian25(vec2 uv) {
    vec2 px = 1.25 / max(iResolution, vec2(1.0));
    vec3 sum = vec3(0.0);
    float total = 0.0;
    for (int y = -2; y <= 2; ++y) {
        for (int x = -2; x <= 2; ++x) {
            vec2 offset = vec2(float(x), float(y));
            float weight = exp(-dot(offset, offset) * 0.42);
            sum += texture(samp, uv + offset * px).rgb * weight;
            total += weight;
        }
    }
    return sum / total;
}

void main(void) {
    vec2 p = tc - 0.5;
    float radius = length(p);
    vec3 blur = gaussian25(tc);
    float luminance = dot(blur, vec3(0.299, 0.587, 0.114));
    vec2 direction = normalize(p + vec2(0.0001));
    float split = 0.0015 + 0.003 * sin(radius * 18.0 - time_f * 0.7);
    vec3 prism =
        vec3(gaussian25(tc + direction * split).r, blur.g, gaussian25(tc - direction * split).b);

    float key = 1.75 + 0.35 * sin(time_f * 0.2 + luminance * 3.0);
    vec3 bits = xorColor(prism, blur.bgr * key);
    vec3 velvet = palette(luminance * 0.65 + radius * 0.3 + time_f * 0.015);
    float sheen = pow(0.5 + 0.5 * sin(radius * 32.0 - time_f * 1.6), 8.0);

    vec3 result = mix(prism, bits, 0.34);
    result = mix(result, result * velvet * 1.3, 0.38);
    result += velvet * sheen * 0.16;
    result = pow(clamp(result, 0.0, 1.0), vec3(0.92));
    color = vec4(result, texture(samp, tc).a);
}
