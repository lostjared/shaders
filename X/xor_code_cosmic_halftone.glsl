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
    return 0.5 + 0.5 * cos(6.2831853 * (t + vec3(0.03, 0.37, 0.68)));
}

void main(void) {
    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 grid = tc * vec2(72.0 * aspect, 72.0);
    vec2 id = floor(grid);
    vec2 cell = fract(grid) - 0.5;
    vec2 centerUV = (id + 0.5) / vec2(72.0 * aspect, 72.0);

    vec3 sampled = texture(samp, centerUV).rgb;
    float luminance = dot(sampled, vec3(0.299, 0.587, 0.114));
    float star = hash21(id);
    float radius = mix(0.08, 0.52, luminance);
    float dotMask = 1.0 - smoothstep(radius - 0.06, radius + 0.06, length(cell));

    vec3 key = palette(star + time_f * 0.02 + luminance * 0.4);
    vec3 bits = xorColor(sampled, key * (1.2 + star * 1.8));
    float twinkle = 0.65 + 0.35 * sin(time_f * (2.0 + star * 4.0) + star * 30.0);
    vec3 paper = texture(samp, tc).rgb * vec3(0.12, 0.15, 0.22);
    vec3 ink = mix(bits, bits * key * 1.5, 0.45) * twinkle;
    vec3 result = mix(paper, ink, dotMask);
    result += key * pow(dotMask, 8.0) * star * 0.22;
    color = vec4(clamp(result, 0.0, 1.0), texture(samp, tc).a);
}
