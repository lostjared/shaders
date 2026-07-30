#version 330 core
// Neon logarithmic spiral trails with high-frequency color ignition.
#define EFFECT_ID 35

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
    return 0.5 + 0.5 * cos(TAU * (phase + vec3(0.03, 0.29, 0.61)));
}

vec4 sample_cache(int index, vec2 uv) {
    return texture(history, vec3(mirror_repeat(uv), float(CACHE_HISTORY_LAYER(index))));
}

float sample_history(int index, float frequency) {
    int max_age = max(min(SIZE, spectrum_history_size) - 1, 0);
    int age = min(index + 1, max_age);
    return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(age)))).r;
}

vec2 spiral_warp(vec2 uv, vec2 center, float depth, float bass, float high) {
    vec2 point = uv - center;
    float radius = max(length(point), 0.002);
    float angle = atan(point.y, point.x);
    angle += log(radius + 0.08) * (0.8 + high * 2.5) + depth * 2.2 - time_f * 0.25;
    radius /= 1.0 + depth * (0.38 + bass * 1.1);
    radius += sin(angle * 7.0 - time_f * 2.0) * high * 0.008;
    return vec2(cos(angle), sin(angle)) * radius + center;
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
        float high = sample_history(index, 0.67);
        vec2 uv = spiral_warp(tc, center, depth, bass, high);
        float spiral = sin(atan(uv.y - center.y, uv.x - center.x) * 8.0 +
                           log(length(uv - center) + 0.03) * 10.0);
        float neon = smoothstep(0.72, 1.0, abs(spiral));
        float weight = mix(0.09, 0.58, depth) * (0.65 + neon * 0.55);
        accumulated += sample_cache(index, uv).rgb * palette(depth + high + time_f * 0.05) * weight;
        total_weight += weight;
    }

    vec3 result = accumulated / total_weight;
    result += result * palette(time_f * 0.1) * amp_peak * 0.18;
    result = (result - 0.5) * (1.12 + amp_smooth * 0.25) + 0.5;
    color = vec4(clamp(result, 0.0, 1.0), live.a);
}
