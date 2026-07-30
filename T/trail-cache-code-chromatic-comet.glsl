#version 330 core
// Directional RGB comet tails accelerated by bass and peak energy.
#define EFFECT_ID 33

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
    return 0.5 + 0.5 * cos(TAU * (phase + vec3(0.00, 0.36, 0.70)));
}

vec4 sample_cache(int index, vec2 uv) {
    return texture(history, vec3(mirror_repeat(uv), float(CACHE_HISTORY_LAYER(index))));
}

float sample_history(int index, float frequency) {
    int max_age = max(min(SIZE, spectrum_history_size) - 1, 0);
    int age = min(index + 1, max_age);
    return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(age)))).r;
}

vec2 comet_warp(vec2 uv, float depth, float bass, float high) {
    float direction = time_f * 0.23 + sin(time_f * 0.11) * 1.4;
    vec2 velocity = vec2(cos(direction), sin(direction));
    uv -= velocity * depth * (0.035 + bass * 0.16);
    vec2 normal = vec2(-velocity.y, velocity.x);
    uv += normal * sin(dot(uv, normal) * 20.0 + time_f * 3.0 - depth * TAU) * high * 0.025;
    return (uv - 0.5) / (1.0 + depth * 0.22) + 0.5;
}

void main() {
    vec4 live = texture(samp, tc);
    vec3 accumulated = live.rgb;
    float total_weight = 1.0;

    for (int index = 0; index < SIZE; ++index) {
        float depth = float(index) / float(max(SIZE - 1, 1));
        float bass = sample_history(index, 0.03);
        float high = sample_history(index, 0.65);
        vec2 uv = comet_warp(tc, depth, bass, high);
        float spread = (0.002 + high * 0.008) * depth;
        vec3 cached;
        cached.r = sample_cache(index, uv + vec2(spread, 0.0)).r;
        cached.g = sample_cache(index, uv).g;
        cached.b = sample_cache(index, uv - vec2(spread, 0.0)).b;
        float weight = mix(0.08, 0.64, depth) * (1.0 - depth * 0.25);
        accumulated += cached * palette(depth * 0.7 + time_f * 0.04) * weight;
        total_weight += weight;
    }

    vec3 result = accumulated / total_weight;
    result += max(result - result.gbr, 0.0) * amp_peak * 0.3;
    result = (result - 0.5) * (1.08 + amp_smooth * 0.26) + 0.5;
    color = vec4(clamp(result, 0.0, 1.0), live.a);
}
