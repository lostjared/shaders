#version 330 core
// Energy cache code: magnetic ribbons sweep spectral memory through the room.

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
uniform float amp_peak;
uniform float amp_smooth;
const float TAU = 6.28318530718;

vec2 mirror_repeat(vec2 point) { return 1.0 - abs(mod(point, 2.0) - 1.0); }
vec3 palette(float phase) { return 0.5 + 0.5 * cos(TAU * (phase + vec3(0.12, 0.44, 0.76))); }
vec3 sample_cache(int index, vec2 uv) { return texture(history, vec3(mirror_repeat(uv), float(CACHE_HISTORY_LAYER(index)))).rgb; }
float history_fft(int index, float frequency) {
    int maximum_age = max(min(SIZE, spectrum_history_size) - 1, 0);
    int age = min(index + 1, maximum_age);
    return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(age)))).r;
}

float ribbons(vec2 point, float bass, float middle, float high) {
    float first = sin(point.y * (16.0 + middle * 9.0) + sin(point.x * 8.0 - time_f * 2.0) * 3.0 + time_f * 4.0);
    float second = sin(point.x * (19.0 + high * 8.0) + cos(point.y * 7.0 + time_f) * 3.5 - time_f * 3.0);
    float braid = sin((point.x - point.y) * 24.0 + first * 2.5 + second * 2.0 + bass * 4.0);
    return 1.0 - abs((first + second + braid) / 3.0);
}

void main() {
    vec2 resolution = max(iResolution, vec2(1.0));
    vec2 aspect = vec2(resolution.x / resolution.y, 1.0);
    vec2 point = (tc - 0.5) * aspect;
    float bass = texture(spectrum0, 0.045).r;
    float middle = texture(spectrum0, 0.33).r;
    float high = texture(spectrum0, 0.79).r;
    float ribbon = ribbons(point, bass, middle, high);
    vec2 warp = vec2(ribbons(point.yx + 0.13, high, bass, middle), ribbon) * (0.025 + middle * 0.05) - (0.0125 + middle * 0.025);
    vec3 live = texture(samp, mirror_repeat(tc + warp)).rgb;
    live *= 0.73 + palette(ribbon * 0.35 + point.y * 0.15 + time_f * 0.08) * 0.88;
    live += palette(point.x * 0.2 - time_f * 0.14) * pow(ribbon, 5.0) * (0.75 + high * 2.5);

    vec3 accumulated = live * 1.12;
    float total_weight = 1.12;
    for (int index = 0; index < SIZE; ++index) {
        float generation = float(index + 1);
        float age = generation / float(max(SIZE, 1));
        vec3 old_audio = vec3(history_fft(index, 0.045), history_fft(index, 0.33), history_fft(index, 0.79));
        vec2 cache_point = point;
        cache_point.x += sin(cache_point.y * 12.0 + generation + time_f * 0.7) * age * (0.045 + old_audio.y * 0.07);
        cache_point.y += cos(cache_point.x * 10.0 - generation + time_f * 0.5) * age * (0.035 + old_audio.z * 0.06);
        cache_point *= 1.0 - age * (0.045 + old_audio.x * 0.055);
        vec3 memory = sample_cache(index, cache_point / aspect + 0.5);
        memory *= palette(age * 0.85 + old_audio.y * 0.45 + ribbon * 0.14);
        float weight = exp(-age * 1.8) * (0.8 + old_audio.y * 0.45);
        accumulated += memory * weight;
        total_weight += weight;
    }
    vec3 result = accumulated / total_weight;
    result += palette(ribbon + time_f * 0.07) * pow(ribbon, 7.0) * (0.45 + amp_peak * 1.4);
    result = (result - 0.5) * (1.26 + amp_smooth * 0.29) + 0.5;
    color = vec4(clamp(result, 0.0, 1.0), 1.0);
}
