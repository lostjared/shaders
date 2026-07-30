#version 330 core
// Fluid lattice refraction ripples through the temporal cache.
#define EFFECT_ID 34

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
    return 0.5 + 0.5 * cos(TAU * (phase + vec3(0.18, 0.47, 0.76)));
}

vec4 sample_cache(int index, vec2 uv) {
    return texture(history, vec3(mirror_repeat(uv), float(CACHE_HISTORY_LAYER(index))));
}

float sample_history(int index, float frequency) {
    int max_age = max(min(SIZE, spectrum_history_size) - 1, 0);
    int age = min(index + 1, max_age);
    return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(age)))).r;
}

vec2 liquid_warp(vec2 uv, float depth, float bass, float middle) {
    vec2 grid = uv * (8.0 + middle * 5.0);
    vec2 flow;
    flow.x = sin(grid.y + time_f * 1.3 + sin(grid.x * 0.7));
    flow.y = cos(grid.x - time_f * 1.1 + cos(grid.y * 0.8));
    uv += flow * depth * (0.008 + bass * 0.035);
    uv = (uv - 0.5) / (1.0 + depth * (0.18 + bass * 0.6)) + 0.5;
    return uv;
}

void main() {
    vec4 live = texture(samp, tc);
    vec3 accumulated = live.rgb;
    float total_weight = 1.0;

    for (int index = 0; index < SIZE; ++index) {
        float depth = float(index) / float(max(SIZE - 1, 1));
        float bass = sample_history(index, 0.035);
        float middle = sample_history(index, 0.23);
        vec2 uv = liquid_warp(tc, depth, bass, middle);
        vec2 grid = abs(fract(uv * 9.0) - 0.5);
        float lattice = 1.0 - smoothstep(0.02, 0.12, min(grid.x, grid.y));
        float weight = mix(0.09, 0.56, depth) * (0.72 + lattice * 0.38);
        vec3 cached = sample_cache(index, uv).rgb;
        accumulated += mix(cached, cached * palette(depth + middle), 0.6) * weight;
        total_weight += weight;
    }

    vec3 result = accumulated / total_weight;
    result = mix(result, result.bgr, amp_peak * 0.22);
    result = (result - 0.5) * (1.06 + amp_smooth * 0.26) + 0.5;
    color = vec4(clamp(result, 0.0, 1.0), live.a);
}
