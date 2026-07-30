#version 330 core
// Dispersive ribbon trails separated into audio-reactive RGB paths.
#define EFFECT_ID 30

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
    return 0.5 + 0.5 * cos(TAU * (phase + vec3(0.00, 0.33, 0.67)));
}

vec4 sample_cache(int index, vec2 uv) {
    return texture(history, vec3(mirror_repeat(uv), float(CACHE_HISTORY_LAYER(index))));
}

float sample_history(int index, float frequency) {
    int max_age = max(min(SIZE, spectrum_history_size) - 1, 0);
    int age = min(index + 1, max_age);
    return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(age)))).r;
}

vec2 ribbon_warp(vec2 uv, float depth, float bass, float high) {
    float phase = uv.y * 13.0 + time_f * (1.2 + high) - depth * TAU;
    uv.x += sin(phase) * depth * (0.035 + bass * 0.08);
    uv.y += cos(uv.x * 9.0 - time_f * 0.7 + depth * 5.0) * 0.018 * depth;
    uv = (uv - 0.5) / (1.0 + depth * (0.25 + bass * 0.8)) + 0.5;
    return uv;
}

void main() {
    vec4 live = texture(samp, tc);
    vec3 accumulated = live.rgb;
    float total_weight = 1.0;

    for (int index = 0; index < SIZE; ++index) {
        float depth = float(index) / float(max(SIZE - 1, 1));
        float bass = sample_history(index, 0.04);
        float high = sample_history(index, 0.62);
        vec2 uv = ribbon_warp(tc, depth, bass, high);
        vec2 dispersion = vec2(0.004 + high * 0.012, 0.0) * (0.2 + depth);
        vec3 cached;
        cached.r = sample_cache(index, uv + dispersion).r;
        cached.g = sample_cache(index, uv).g;
        cached.b = sample_cache(index, uv - dispersion).b;
        float ribbon = 1.0 - smoothstep(0.05, 0.75, abs(sin(uv.y * 18.0 + time_f - depth * TAU)));
        float weight = mix(0.08, 0.55, depth) * mix(0.55, 1.1, ribbon);
        accumulated += cached * mix(vec3(1.0), palette(depth + high), 0.45) * weight;
        total_weight += weight;
    }

    vec3 result = accumulated / total_weight;
    result += (result - result.gbr) * amp_peak * 0.15;
    result = (result - 0.5) * (1.08 + amp_smooth * 0.25) + 0.5;
    color = vec4(clamp(result, 0.0, 1.0), live.a);
}
