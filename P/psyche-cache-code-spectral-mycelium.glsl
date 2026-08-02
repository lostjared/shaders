#version 330 core
// Branching spectral filaments carry cached frames through a neon network.

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

float hash_21(vec2 point) {
    return fract(sin(dot(point, vec2(127.1, 311.7))) * 43758.5453);
}

float network(vec2 point) {
    vec2 cell = floor(point);
    vec2 part = fract(point) - 0.5;
    float nearest = 2.0;
    for (int y = -1; y <= 1; ++y) {
        for (int x = -1; x <= 1; ++x) {
            vec2 offset = vec2(float(x), float(y));
            vec2 seed = vec2(hash_21(cell + offset),
                             hash_21(cell + offset + 9.3)) - 0.5;
            nearest = min(nearest, length(offset + seed - part));
        }
    }
    return exp(-nearest * 8.0);
}

vec3 palette(float phase) {
    return 0.5 + 0.5 * cos(TAU * (phase + vec3(0.16, 0.49, 0.78)));
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

void main() {
    vec2 resolution = max(iResolution, vec2(1.0));
    float aspect = resolution.x / resolution.y;
    vec2 center = iMouse.z > 0.0 ? iMouse.xy / resolution : vec2(0.5);
    vec2 point = (tc - center) * vec2(aspect, 1.0);
    float bass = max(texture(spectrum0, 0.045).r, amp_low);
    float middle = max(texture(spectrum0, 0.34).r, amp_mid);
    float treble = max(texture(spectrum0, 0.81).r, amp_high);
    vec2 warped = point;
    for (int fold = 0; fold < 3; ++fold) {
        warped = abs(warped) - vec2(0.28 + bass * 0.035);
        warped = rotate_2d(0.72 + middle * 0.35 + float(fold) * 0.23) * warped;
    }
    float filaments = network(warped * (10.0 + treble * 7.0) + time_f * 0.12);
    vec2 direction = normalize(warped + vec2(0.0001));
    vec2 live_uv = tc + direction * (filaments - 0.35) * (0.025 + bass * 0.055);
    vec3 live = texture(samp, mirror_repeat(live_uv)).rgb;
    live += palette(filaments + time_f * 0.04) * filaments *
            (0.16 + treble * 0.34);

    vec3 accumulated = live * 1.15;
    float total_weight = 1.15;
    for (int index = 0; index < SIZE; ++index) {
        float age = float(index + 1) / float(max(SIZE, 1));
        float old_middle = history_fft(index, 0.34);
        float old_treble = history_fft(index, 0.81);
        vec2 cache_uv = tc - center;
        cache_uv = rotate_2d((old_middle - 0.3) * age * 1.2) * cache_uv;
        cache_uv *= 1.0 - age * (0.08 + old_treble * 0.06);
        cache_uv += direction * filaments * old_treble * 0.025 * age;
        cache_uv += center;
        vec3 memory = sample_cache(index, cache_uv);
        memory = mix(memory, memory.gbr, old_treble * 0.45);
        memory *= 0.7 + palette(age * 1.5 + filaments) * 0.48;
        float weight = exp(-age * 2.45) * (0.75 + filaments * 0.35);
        accumulated += memory * weight;
        total_weight += weight;
    }

    vec3 result = accumulated / total_weight;
    result += palette(filaments - time_f * 0.03) * filaments * amp_peak * 0.16;
    result = (result - 0.5) * (1.08 + amp_smooth * 0.28) + 0.5;
    color = vec4(clamp(result, 0.0, 1.0), texture(samp, tc).a);
}
