#version 330 core
// Audio-gated helical trails with a rhythmic strobe shutter.
#define EFFECT_ID 25

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
    return 0.5 + 0.5 * cos(TAU * (phase + vec3(0.00, 0.31, 0.67)));
}

vec4 sample_cache(int index, vec2 uv) {
    return texture(history, vec3(mirror_repeat(uv), float(CACHE_HISTORY_LAYER(index))));
}

float sample_history(int index, float frequency) {
    int max_age = max(min(SIZE, spectrum_history_size) - 1, 0);
    int age = min(index + 1, max_age);
    return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(age)))).r;
}

vec2 trail_transform(vec2 uv, vec2 center, float depth, float bass, float treble) {
    vec2 point = uv - center;
    float radius = length(point);
    float helix = depth * (1.0 + treble * 2.5) + radius * 5.0;
    point = rotate_2d(sin(time_f * 0.8 + helix) * depth * 1.4) * point;
    point /= 1.0 + depth * (0.3 + bass * 1.8);
    point.x += sin(radius * 18.0 - time_f * 4.0 + helix) * 0.018 * depth;
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
        float treble = sample_history(index, 0.61);
        vec2 uv = trail_transform(tc, center, depth, bass, treble);
        float shutter = step(0.28, fract(time_f * (3.0 + amp_high * 5.0) - depth * 1.7));
        float weight = mix(0.08, 0.65, depth) * mix(0.18, 1.0, shutter);
        vec3 tint = palette(depth + time_f * 0.08 + treble);
        accumulated += sample_cache(index, uv).rgb * tint * weight;
        total_weight += weight;
    }

    vec3 result = accumulated / total_weight;
    float flash = smoothstep(0.82, 1.0, amp_peak) * step(0.55, fract(time_f * 8.0));
    result = mix(result, vec3(1.0) - result, flash * 0.6);
    result = (result - 0.5) * (1.05 + amp_smooth * 0.3) + 0.5;
    color = vec4(clamp(result, 0.0, 1.0), live.a);
}
