#version 330 core
// Strobing scanline shutters slice and reorder the temporal trail.
#define EFFECT_ID 39

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

float hash_1d(float value) {
    return fract(sin(value * 91.3458) * 47453.5453);
}

vec3 palette(float phase) {
    return 0.5 + 0.5 * cos(TAU * (phase + vec3(0.02, 0.37, 0.71)));
}

vec4 sample_cache(int index, vec2 uv) {
    return texture(history, vec3(mirror_repeat(uv), float(CACHE_HISTORY_LAYER(index))));
}

float sample_history(int index, float frequency) {
    int max_age = max(min(SIZE, spectrum_history_size) - 1, 0);
    int age = min(index + 1, max_age);
    return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(age)))).r;
}

vec2 glitch_warp(vec2 uv, float depth, float bass, float high) {
    float row = floor(uv.y * (18.0 + high * 24.0));
    float tick = floor(time_f * (6.0 + bass * 10.0));
    float random_value = hash_1d(row + tick * 37.0 + depth * 11.0);
    float gate = step(0.7 - high * 0.2, random_value);
    uv.x += (random_value - 0.5) * gate * depth * (0.08 + bass * 0.2);
    uv.y += (hash_1d(row * 3.1 + tick) - 0.5) * gate * 0.025;
    return (uv - 0.5) / (1.0 + depth * 0.14) + 0.5;
}

void main() {
    vec4 live = texture(samp, tc);
    vec3 accumulated = live.rgb;
    float total_weight = 1.0;

    for (int index = 0; index < SIZE; ++index) {
        float depth = float(index) / float(max(SIZE - 1, 1));
        float bass = sample_history(index, 0.03);
        float high = sample_history(index, 0.68);
        vec2 uv = glitch_warp(tc, depth, bass, high);
        float shutter = step(0.35, fract(time_f * 7.0 + depth * 2.3 + floor(tc.y * 20.0) * 0.17));
        float weight = mix(0.06, 0.52, depth) * mix(0.22, 1.15, shutter);
        vec3 cached = sample_cache(index, uv).rgb;
        cached = mix(cached, cached.brg, step(0.75, hash_1d(float(index) + floor(time_f * 5.0))));
        accumulated += cached * palette(depth + high) * weight;
        total_weight += weight;
    }

    vec3 result = accumulated / total_weight;
    result = mix(result, vec3(1.0) - result, smoothstep(0.9, 1.0, amp_peak) * 0.45);
    result = (result - 0.5) * (1.14 + amp_smooth * 0.24) + 0.5;
    color = vec4(clamp(result, 0.0, 1.0), live.a);
}
