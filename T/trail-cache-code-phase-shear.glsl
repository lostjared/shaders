#version 330 core
// Orthogonal phase shears split temporal layers into oscillating planes.
#define EFFECT_ID 48

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

vec2 mirror_repeat(vec2 point) {
    return 1.0 - abs(mod(point, 2.0) - 1.0);
}

vec3 palette(float phase) {
    return 0.5 + 0.5 * cos(TAU * (phase + vec3(0.01, 0.35, 0.69)));
}

vec4 sample_cache(int index, vec2 uv) {
    return texture(history, vec3(mirror_repeat(uv), float(CACHE_HISTORY_LAYER(index))));
}

float sample_history(int index, float frequency) {
    int max_age = max(min(SIZE, spectrum_history_size) - 1, 0);
    int age = min(index + 1, max_age);
    return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(age)))).r;
}

vec2 phase_warp(vec2 uv, float depth, float bass, float high) {
    vec2 point = uv - 0.5;
    float phase_x = sin(point.y * 14.0 + time_f * 1.3 + depth * TAU);
    float phase_y = cos(point.x * 11.0 - time_f * 0.9 - depth * 4.0);
    point.x += phase_x * depth * (0.012 + bass * 0.055);
    point.y += phase_y * depth * (0.012 + high * 0.045);
    float shear = sin(time_f * 0.37 + depth * TAU) * (0.08 + high * 0.2);
    point = mat2(1.0, shear, -shear, 1.0) * point;
    return point / (1.0 + depth * 0.2) + 0.5;
}

void main() {
    vec4 live = texture(samp, tc);
    vec3 accumulated = live.rgb;
    float total_weight = 1.0;

    for (int index = 0; index < SIZE; ++index) {
        float depth = float(index) / float(max(SIZE - 1, 1));
        float bass = sample_history(index, 0.03);
        float high = sample_history(index, 0.62);
        vec2 uv = phase_warp(tc, depth, bass, high);
        float grid = 0.5 + 0.5 * sin(uv.x * 25.0 + time_f) * cos(uv.y * 21.0 - time_f);
        float weight = mix(0.08, 0.55, depth) * mix(0.65, 1.1, grid);
        vec3 cached = sample_cache(index, uv).rgb;
        accumulated += mix(cached, cached.gbr * palette(depth + high), 0.52) * weight;
        total_weight += weight;
    }

    vec3 result = accumulated / total_weight;
    result = mix(result, vec3(1.0) - result, amp_peak * step(0.7, fract(time_f * 5.0)) * 0.28);
    result = (result - 0.5) * (1.1 + amp_smooth * 0.25) + 0.5;
    color = vec4(clamp(result, 0.0, 1.0), live.a);
}
