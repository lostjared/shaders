#version 330 core
// Lens-like gravitational trails spiral toward the mouse or frame center.
#define EFFECT_ID 32

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
    return 0.5 + 0.5 * cos(TAU * (phase + vec3(0.09, 0.40, 0.73)));
}

vec4 sample_cache(int index, vec2 uv) {
    return texture(history, vec3(mirror_repeat(uv), float(CACHE_HISTORY_LAYER(index))));
}

float sample_history(int index, float frequency) {
    int max_age = max(min(SIZE, spectrum_history_size) - 1, 0);
    int age = min(index + 1, max_age);
    return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(age)))).r;
}

vec2 gravity_warp(vec2 uv, vec2 center, float depth, float bass, float high) {
    vec2 point = uv - center;
    float radius = max(length(point), 0.035);
    float lens = depth * (0.008 + bass * 0.035) / (radius * radius + 0.04);
    point = rotate_2d(lens * (1.0 + high * 2.0) + time_f * 0.02 * depth) * point;
    point *= 1.0 + lens * 0.18 - depth * 0.18;
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
        float bass = sample_history(index, 0.025);
        float high = sample_history(index, 0.58);
        vec2 uv = gravity_warp(tc, center, depth, bass, high);
        float radius = length(tc - center);
        float disk = 1.0 - smoothstep(0.08, 0.3, abs(radius - 0.16 - bass * 0.04));
        float weight = mix(0.08, 0.62, depth) * (0.7 + disk * 0.55);
        accumulated += sample_cache(index, uv).rgb * mix(vec3(1.0), palette(depth + high), 0.6) * weight;
        total_weight += weight;
    }

    vec3 result = accumulated / total_weight;
    float core = 1.0 - smoothstep(0.0, 0.12, length(tc - center));
    result = mix(result, palette(time_f * 0.08) * result, core * (0.4 + amp_low));
    result = (result - 0.5) * (1.1 + amp_smooth * 0.25) + 0.5;
    color = vec4(clamp(result, 0.0, 1.0), live.a);
}
