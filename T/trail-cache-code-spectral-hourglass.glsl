#version 330 core
// Temporal layers squeeze through an audio-reactive spectral hourglass.
#define EFFECT_ID 37

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
    return 0.5 + 0.5 * cos(TAU * (phase + vec3(0.22, 0.54, 0.88)));
}

vec4 sample_cache(int index, vec2 uv) {
    return texture(history, vec3(mirror_repeat(uv), float(CACHE_HISTORY_LAYER(index))));
}

float sample_history(int index, float frequency) {
    int max_age = max(min(SIZE, spectrum_history_size) - 1, 0);
    int age = min(index + 1, max_age);
    return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(age)))).r;
}

vec2 hourglass_warp(vec2 uv, vec2 center, float depth, float bass, float high) {
    vec2 point = uv - center;
    float waist = 0.35 + abs(point.y) * (1.5 + high);
    point.x /= waist;
    point.x += sin(point.y * 18.0 - time_f * 2.0 + depth * TAU) * (0.015 + high * 0.035);
    point.y /= 1.0 + depth * (0.28 + bass);
    point.x /= 1.0 + depth * (0.18 + bass * 0.7);
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
        float high = sample_history(index, 0.6);
        vec2 uv = hourglass_warp(tc, center, depth, bass, high);
        float waist = (1.0 - smoothstep(0.0, 0.2, abs(tc.x - center.x))) *
                      (1.0 - smoothstep(0.05, 0.48, abs(tc.y - center.y)));
        float weight = mix(0.09, 0.57, depth) * (0.7 + waist * 0.5);
        accumulated += sample_cache(index, uv).rgb * palette(depth + high + time_f * 0.04) * weight;
        total_weight += weight;
    }

    vec3 result = accumulated / total_weight;
    result += palette(length(tc - center) + time_f * 0.04) * amp_peak * 0.1;
    result = (result - 0.5) * (1.1 + amp_smooth * 0.25) + 0.5;
    color = vec4(clamp(result, 0.0, 1.0), live.a);
}
