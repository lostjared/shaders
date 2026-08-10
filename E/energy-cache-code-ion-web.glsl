#version 330 core
// Energy cache code: a charged web binds live video to spectral memory.

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
float hash_21(vec2 point) { return fract(sin(dot(point, vec2(127.1, 311.7))) * 43758.5453123); }
vec3 palette(float phase) { return 0.5 + 0.5 * cos(TAU * (phase + vec3(0.06, 0.41, 0.78))); }
vec3 sample_cache(int index, vec2 uv) { return texture(history, vec3(mirror_repeat(uv), float(CACHE_HISTORY_LAYER(index)))).rgb; }
float history_fft(int index, float frequency) {
    int maximum_age = max(min(SIZE, spectrum_history_size) - 1, 0);
    int age = min(index + 1, maximum_age);
    return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(age)))).r;
}

float ion_cells(vec2 point, float scale) {
    vec2 grid = point * scale;
    vec2 cell = floor(grid);
    vec2 local = fract(grid) - 0.5;
    float nearest = 2.0;
    for (int y = -1; y <= 1; ++y) {
        for (int x = -1; x <= 1; ++x) {
            vec2 offset = vec2(float(x), float(y));
            vec2 seed = vec2(hash_21(cell + offset), hash_21(cell + offset + 17.3)) - 0.5;
            seed += 0.28 * vec2(sin(time_f + seed.x * TAU), cos(time_f * 0.8 + seed.y * TAU));
            nearest = min(nearest, length(local - offset - seed));
        }
    }
    return nearest;
}

void main() {
    vec2 resolution = max(iResolution, vec2(1.0));
    vec2 aspect = vec2(resolution.x / resolution.y, 1.0);
    vec2 point = (tc - 0.5) * aspect;
    float bass = texture(spectrum0, 0.04).r;
    float middle = texture(spectrum0, 0.27).r;
    float high = texture(spectrum0, 0.73).r;
    float cells = ion_cells(point, 7.0 + middle * 4.0);
    float web = exp(-abs(cells - 0.43) * (38.0 + high * 20.0));
    vec2 warp = vec2(sin(point.y * 23.0 + time_f * 4.0), cos(point.x * 21.0 - time_f * 3.0)) * web * (0.025 + bass * 0.04);
    vec3 live = texture(samp, mirror_repeat(tc + warp)).rgb;
    live *= 0.75 + palette(cells + time_f * 0.06) * 0.8;
    live += palette(cells * 0.8 - time_f * 0.13) * web * (0.9 + high * 2.7);

    vec3 accumulated = live;
    float total_weight = 1.0;
    for (int index = 0; index < SIZE; ++index) {
        float generation = float(index + 1);
        float age = generation / float(max(SIZE, 1));
        vec3 old_audio = vec3(history_fft(index, 0.04), history_fft(index, 0.27), history_fft(index, 0.73));
        vec2 cache_point = point * (1.0 - age * (0.055 + old_audio.x * 0.075));
        cache_point += vec2(sin(cache_point.y * 14.0 + generation), cos(cache_point.x * 13.0 - generation)) * old_audio.z * age * 0.035;
        vec3 memory = sample_cache(index, cache_point / aspect + 0.5);
        float old_web = exp(-abs(ion_cells(cache_point + age * 0.11, 7.0 + old_audio.y * 4.0) - 0.43) * 30.0);
        memory *= mix(vec3(0.65), palette(age + old_audio.y), 0.55 + old_web * 0.35);
        float weight = pow(0.79, generation) * (0.8 + old_web * 0.6);
        accumulated += memory * weight;
        total_weight += weight;
    }
    vec3 result = accumulated / total_weight;
    result += palette(web + time_f * 0.08) * web * (0.55 + amp_peak * 1.3);
    result = (result - 0.5) * (1.27 + amp_smooth * 0.28) + 0.5;
    color = vec4(clamp(result, 0.0, 1.0), 1.0);
}
