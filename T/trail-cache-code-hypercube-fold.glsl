#version 330 core
// Mirrored hypercube folds with audio-expanded temporal chambers.
#define EFFECT_ID 27

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
    return 0.5 + 0.5 * cos(TAU * (phase + vec3(0.20, 0.52, 0.86)));
}

vec4 sample_cache(int index, vec2 uv) {
    return texture(history, vec3(mirror_repeat(uv), float(CACHE_HISTORY_LAYER(index))));
}

float sample_history(int index, float frequency) {
    int max_age = max(min(SIZE, spectrum_history_size) - 1, 0);
    int age = min(index + 1, max_age);
    return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(age)))).r;
}

vec2 hypercube_fold(vec2 uv, vec2 center, float depth, float bass, float middle) {
    vec2 point = (uv - center) * (2.0 + depth * 1.5);
    point = rotate_2d(depth * 0.8 + sin(time_f * 0.4) * 0.35) * point;
    point = abs(point) - vec2(0.55 + bass * 0.18);
    point = abs(point.yx) - vec2(0.26 + middle * 0.12);
    float w = sin((point.x - point.y) * 5.0 + time_f + depth * TAU);
    point /= 1.0 + depth * 0.7 + w * 0.12;
    return point * 0.5 + center;
}

void main() {
    vec2 resolution = max(iResolution, vec2(1.0));
    vec2 center = iMouse.z > 0.0 ? iMouse.xy / resolution : vec2(0.5);
    vec4 live = texture(samp, tc);
    vec3 accumulated = live.rgb * 0.8;
    float total_weight = 0.8;

    for (int index = 0; index < SIZE; ++index) {
        float depth = float(index) / float(max(SIZE - 1, 1));
        float bass = sample_history(index, 0.04);
        float middle = sample_history(index, 0.27);
        vec2 uv = hypercube_fold(tc, center, depth, bass, middle);
        float frame = 1.0 - smoothstep(0.0, 0.03, abs(max(abs(uv.x - center.x), abs(uv.y - center.y)) - 0.22));
        float weight = mix(0.1, 0.54, depth) + frame * 0.2;
        vec3 cached = sample_cache(index, uv).rgb;
        accumulated += mix(cached, cached * palette(depth + middle), 0.72) * weight;
        total_weight += weight;
    }

    vec3 result = accumulated / total_weight;
    result = mix(result, result.bgr, amp_peak * 0.35);
    result = (result - 0.5) * (1.12 + amp_smooth * 0.2) + 0.5;
    color = vec4(clamp(result, 0.0, 1.0), live.a);
}
