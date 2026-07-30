#version 330 core
// Falling diamond cells refract and stagger temporal color trails.
#define EFFECT_ID 46

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
    return fract(sin(value * 127.1) * 43758.5453);
}

vec3 palette(float phase) {
    return 0.5 + 0.5 * cos(TAU * (phase + vec3(0.13, 0.47, 0.81)));
}

vec4 sample_cache(int index, vec2 uv) {
    return texture(history, vec3(mirror_repeat(uv), float(CACHE_HISTORY_LAYER(index))));
}

float sample_history(int index, float frequency) {
    int max_age = max(min(SIZE, spectrum_history_size) - 1, 0);
    int age = min(index + 1, max_age);
    return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(age)))).r;
}

vec2 diamond_warp(vec2 uv, float depth, float bass, float high) {
    float column = floor(uv.x * 12.0);
    float speed = 0.18 + hash_1d(column) * 0.35 + bass * 0.5;
    uv.y += time_f * speed * depth;
    vec2 cell = fract(uv * vec2(12.0, 8.0)) - 0.5;
    float diamond = abs(cell.x) + abs(cell.y);
    uv.x += sign(cell.x) * (1.0 - smoothstep(0.0, 0.5, diamond)) * high * depth * 0.025;
    uv.y -= depth * (0.02 + bass * 0.08);
    return uv;
}

void main() {
    vec4 live = texture(samp, tc);
    vec3 accumulated = live.rgb;
    float total_weight = 1.0;

    for (int index = 0; index < SIZE; ++index) {
        float depth = float(index) / float(max(SIZE - 1, 1));
        float bass = sample_history(index, 0.03);
        float high = sample_history(index, 0.61);
        vec2 uv = diamond_warp(tc, depth, bass, high);
        vec2 cell = abs(fract(uv * vec2(12.0, 8.0)) - 0.5);
        float gem = 1.0 - smoothstep(0.28, 0.55, cell.x + cell.y);
        float weight = mix(0.06, 0.5, depth) * (0.5 + gem * 0.8);
        vec3 cached = sample_cache(index, uv).rgb;
        accumulated += mix(cached, cached.rbg * palette(depth + high), 0.56) * weight;
        total_weight += weight;
    }

    vec3 result = accumulated / total_weight;
    result += palette(tc.y + time_f * 0.08) * amp_peak * 0.1;
    result = (result - 0.5) * (1.12 + amp_smooth * 0.24) + 0.5;
    color = vec4(clamp(result, 0.0, 1.0), live.a);
}
