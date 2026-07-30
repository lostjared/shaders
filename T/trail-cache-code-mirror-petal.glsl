#version 330 core
// Mirrored flower petals open and close through successive history layers.
#define EFFECT_ID 36

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
    return 0.5 + 0.5 * cos(TAU * (phase + vec3(0.10, 0.43, 0.77)));
}

vec4 sample_cache(int index, vec2 uv) {
    return texture(history, vec3(mirror_repeat(uv), float(CACHE_HISTORY_LAYER(index))));
}

float sample_history(int index, float frequency) {
    int max_age = max(min(SIZE, spectrum_history_size) - 1, 0);
    int age = min(index + 1, max_age);
    return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(age)))).r;
}

vec2 petal_warp(vec2 uv, vec2 center, float depth, float bass, float middle) {
    vec2 point = uv - center;
    float radius = length(point);
    float angle = atan(point.y, point.x);
    float petals = 5.0 + floor(middle * 4.0);
    angle = abs(mod(angle + 3.14159265 / petals, TAU / petals) - 3.14159265 / petals);
    radius *= 1.0 + cos(angle * petals) * (0.16 + bass * 0.28);
    angle += depth * (0.45 + middle) * sin(time_f * 0.5);
    radius /= 1.0 + depth * (0.32 + bass * 0.8);
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
        float bass = sample_history(index, 0.035);
        float middle = sample_history(index, 0.3);
        vec2 uv = petal_warp(tc, center, depth, bass, middle);
        float angle = atan(tc.y - center.y, tc.x - center.x);
        float petal = pow(abs(cos(angle * 5.0)), 5.0);
        float weight = mix(0.1, 0.55, depth) * (0.72 + petal * 0.4);
        vec3 cached = sample_cache(index, uv).rgb;
        accumulated += mix(cached, cached.gbr * palette(depth + middle), 0.48) * weight;
        total_weight += weight;
    }

    vec3 result = accumulated / total_weight;
    result = mix(result, result.bgr, smoothstep(0.88, 1.0, amp_peak) * 0.3);
    result = (result - 0.5) * (1.1 + amp_smooth * 0.24) + 0.5;
    color = vec4(clamp(result, 0.0, 1.0), live.a);
}
