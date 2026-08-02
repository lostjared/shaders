#version 330 core
// Plasma petals open at different times across the audio-aligned cache.

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
    float cosine = cos(angle);
    float sine = sin(angle);
    return mat2(cosine, -sine, sine, cosine);
}

vec2 mirror_repeat(vec2 point) {
    return 1.0 - abs(mod(point, 2.0) - 1.0);
}

vec3 palette(float phase) {
    return 0.5 + 0.5 * cos(TAU * (phase + vec3(0.17, 0.51, 0.86)));
}

vec3 sample_cache(int index, vec2 uv) {
    return texture(history, vec3(mirror_repeat(uv),
                   float(CACHE_HISTORY_LAYER(index)))).rgb;
}

float history_fft(int index, float frequency) {
    int age = min(index + 1, max(spectrum_history_size - 1, 0));
    return texture(spectrum_history,
                   vec2(frequency, float(SPECTRUM_HISTORY_LAYER(age)))).r;
}

vec2 flower_map(vec2 point, float bass, float middle, float treble, float age) {
    float radius = length(point) + 0.0001;
    float angle = atan(point.y, point.x);
    float petals = 7.0 + floor(treble * 6.0);
    float envelope = 1.0 + cos(angle * petals - time_f * 1.2 - age * 8.0) *
                     (0.18 + middle * 0.16);
    radius *= envelope;
    angle += sin(radius * (11.0 + bass * 7.0) - time_f * 2.0) *
             (0.15 + treble * 0.22);
    return vec2(cos(angle), sin(angle)) * radius;
}

void main() {
    vec2 resolution = max(iResolution, vec2(1.0));
    float aspect = resolution.x / resolution.y;
    vec2 center = iMouse.z > 0.0 ? iMouse.xy / resolution : vec2(0.5);
    vec2 point = (tc - center) * vec2(aspect, 1.0);
    float bass = max(texture(spectrum0, 0.028).r, amp_low);
    float middle = max(texture(spectrum0, 0.27).r, amp_mid);
    float treble = max(texture(spectrum0, 0.71).r, amp_high);
    vec2 flower = flower_map(point, bass, middle, treble, 0.0);
    float radius = length(flower) + 0.0001;
    float angle = atan(flower.y, flower.x);
    float plasma = sin(flower.x * (18.0 + treble * 9.0) + time_f * 2.4) +
                   cos(flower.y * (21.0 + middle * 8.0) - time_f * 1.9) +
                   sin(radius * (32.0 + bass * 20.0) - time_f * 6.0);
    vec2 live_uv = flower / vec2(aspect, 1.0) + center;
    live_uv += vec2(cos(plasma), sin(plasma)) * plasma *
               (0.004 + bass * 0.012);
    vec3 live = texture(samp, mirror_repeat(live_uv)).rgb;
    live *= 0.68 + palette(plasma * 0.08 + time_f * 0.035) * 0.62;
    float glow = pow(clamp(plasma / 3.0, 0.0, 1.0), 5.0);
    live += palette(angle / TAU + radius) * glow * (0.14 + treble * 0.32);

    vec3 accumulated = live * 1.2;
    float total_weight = 1.2;
    for (int index = 0; index < SIZE; ++index) {
        float age = float(index + 1) / float(max(SIZE, 1));
        float old_bass = history_fft(index, 0.028);
        float old_middle = history_fft(index, 0.27);
        float old_treble = history_fft(index, 0.71);
        vec2 old_flower = flower_map(point, old_bass, old_middle,
                                     old_treble, age);
        old_flower = rotate_2d(age * (0.25 + old_middle * 0.6)) * old_flower;
        old_flower *= 1.0 - age * (0.1 + old_bass * 0.07);
        vec2 cache_uv = old_flower / vec2(aspect, 1.0) + center;
        vec3 memory = sample_cache(index, cache_uv);
        memory = mix(memory, abs(memory - live), old_treble * 0.3);
        memory *= 0.66 + palette(age + length(old_flower)) * 0.59;
        float weight = exp(-age * 2.2) * (0.7 + old_bass * 0.52);
        accumulated += memory * weight;
        total_weight += weight;
    }

    vec3 result = accumulated / total_weight;
    result += palette(plasma * 0.06 + 0.5) * glow * amp_peak * 0.2;
    result = (result - 0.5) * (1.1 + amp_smooth * 0.32) + 0.5;
    color = vec4(clamp(result, 0.0, 1.0), texture(samp, tc).a);
}
