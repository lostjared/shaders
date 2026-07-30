#version 330 core
// Perspective cube faces tumble through the temporal cache.
#define EFFECT_ID 45

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform sampler2DArray history;
uniform int history_head;
#ifndef SIZE
#define SIZE 8
#endif
#ifndef CACHE_HISTORY_LAYER
#define CACHE_HISTORY_LAYER(index) ((history_head + (index)) % SIZE)
#endif
uniform sampler1D spectrum0;
uniform sampler1DArray spectrum_history;
uniform int spectrum_history_head;
uniform int spectrum_history_size;
#ifndef SPECTRUM_HISTORY_LAYER
#define SPECTRUM_HISTORY_LAYER(index) ((spectrum_history_head - ((index) % max(spectrum_history_size, 1)) + max(spectrum_history_size, 1)) % max(spectrum_history_size, 1))
#endif
uniform float time_f;
uniform vec2 iResolution;
uniform vec4 iMouse;
uniform float amp_peak;
uniform float amp_smooth;
uniform float amp_low;
uniform float amp_mid;
uniform float amp_high;

const float TAU = 6.28318530718;

mat2 rotate_2d(float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return mat2(c, -s, s, c);
}

vec2 mirror_repeat(vec2 point) {
    return 1.0 - abs(mod(point, 2.0) - 1.0);
}

vec3 palette(float phase) {
    return 0.5 + 0.5 * cos(TAU * (phase + vec3(0.06, 0.41, 0.77)));
}

vec4 sample_cache(int index, vec2 uv) {
    return texture(history, vec3(mirror_repeat(uv), float(CACHE_HISTORY_LAYER(index))));
}

float sample_history(int index, float frequency) {
    int max_age = max(min(SIZE, spectrum_history_size) - 1, 0);
    int age = min(index + 1, max_age);
    return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(age)))).r;
}

vec2 cube_warp(vec2 uv, vec2 center, float depth, float bass, float high) {
    vec2 point = uv - center;
    float z = 0.42 * sin(point.x * 5.0 + point.y * 5.0 + depth * TAU);
    point = rotate_2d(time_f * 0.12 + depth * 1.4 + high * 0.5) * point;
    float face_x = sign(point.x) * max(abs(point.x), abs(z));
    float face_y = sign(point.y) * max(abs(point.y), abs(z));
    float perspective = 1.0 / max(0.7, 1.45 - z * (0.6 + bass));
    point = vec2(face_x, face_y) * perspective;
    point /= 1.0 + depth * (0.25 + bass * 0.55);
    return point + center;
}

void main() {
    vec2 resolution = max(iResolution, vec2(1.0));
    vec2 center = iMouse.z > 0.0 ? iMouse.xy / resolution : vec2(0.5);
    vec4 live = texture(samp, tc);
    vec3 accumulated = live.rgb;
    float total_weight = 1.0;

    for (int index = 0; index < SIZE; ++index) {
        float depth = float(index) / float(max(SIZE - 1, 1));
        float bass = sample_history(index, 0.03);
        float high = sample_history(index, 0.64);
        vec2 uv = cube_warp(tc, center, depth, bass, high);
        vec2 face = abs(uv - center);
        float edge = 1.0 - smoothstep(0.0, 0.025, abs(max(face.x, face.y) - (0.15 + depth * 0.2)));
        float weight = mix(0.08, 0.55, depth) * (0.68 + edge * 0.65);
        accumulated += sample_cache(index, uv).rgb * palette(depth + high + time_f * 0.04) * weight;
        total_weight += weight;
    }

    vec3 result = accumulated / total_weight;
    result = mix(result, result.brg, amp_peak * 0.28);
    result = (result - 0.5) * (1.12 + amp_smooth * 0.23) + 0.5;
    color = vec4(clamp(result, 0.0, 1.0), live.a);
}
