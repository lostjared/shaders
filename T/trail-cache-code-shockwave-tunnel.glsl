#version 330 core
// Concentric bass shockwaves pull cached frames through a temporal tunnel.
#define EFFECT_ID 29

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
    return 0.5 + 0.5 * cos(TAU * (phase + vec3(0.08, 0.41, 0.75)));
}

vec4 sample_cache(int index, vec2 uv) {
    return texture(history, vec3(mirror_repeat(uv), float(CACHE_HISTORY_LAYER(index))));
}

float sample_history(int index, float frequency) {
    int max_age = max(min(SIZE, spectrum_history_size) - 1, 0);
    int age = min(index + 1, max_age);
    return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(age)))).r;
}

vec2 shockwave_tunnel(vec2 uv, vec2 center, float depth, float bass, float middle) {
    vec2 point = uv - center;
    float radius = max(length(point), 0.0001);
    float wave = sin(radius * 34.0 - time_f * 5.0 - depth * TAU);
    float pulse = exp(-8.0 * abs(fract(radius * 3.5 - time_f * 0.45 + depth) - 0.5));
    float displacement = (wave * 0.012 + pulse * 0.035) * (1.0 + bass * 3.0);
    point *= (radius + displacement) / radius;
    point /= 1.0 + depth * (0.55 + middle);
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
        float middle = sample_history(index, 0.24);
        vec2 uv = shockwave_tunnel(tc, center, depth, bass, middle);
        float ring = 0.55 + 0.45 * sin(length(uv - center) * 45.0 - time_f * 3.0);
        float weight = mix(0.09, 0.62, depth) * mix(0.7, 1.1, ring);
        vec3 cached = sample_cache(index, uv).rgb;
        accumulated += cached * mix(vec3(1.0), palette(depth + bass), 0.7) * weight;
        total_weight += weight;
    }

    vec3 result = accumulated / total_weight;
    result = mix(result, result * palette(time_f * 0.12), amp_low * 0.32);
    result = (result - 0.5) * (1.08 + amp_smooth * 0.24) + 0.5;
    color = vec4(clamp(result, 0.0, 1.0), live.a);
}
