#version 330 core
// Codex cache concept 099: embossed spectrum.
// Remixes repository cache, spectrum-history, coordinate-fold, and palette idioms.

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
    return fract(sin(dot(point, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise_2d(vec2 point) {
    vec2 cell = floor(point);
    vec2 part = fract(point);
    part = part * part * (3.0 - 2.0 * part);
    return mix(mix(hash_21(cell), hash_21(cell + vec2(1.0, 0.0)), part.x),
               mix(hash_21(cell + vec2(0.0, 1.0)), hash_21(cell + vec2(1.0)), part.x),
               part.y);
}

vec3 voronoi_data(vec2 point) {
    vec2 cell = floor(point);
    vec2 part = fract(point);
    float nearest = 4.0;
    float second_nearest = 4.0;
    float identity = 0.0;
    for (int y = -1; y <= 1; ++y) {
        for (int x = -1; x <= 1; ++x) {
            vec2 offset = vec2(float(x), float(y));
            vec2 seed = vec2(hash_21(cell + offset), hash_21(cell + offset + 19.17));
            float distance_to_seed = length(offset + seed - part);
            if (distance_to_seed < nearest) {
                second_nearest = nearest;
                nearest = distance_to_seed;
                identity = hash_21(cell + offset + 7.31);
            } else if (distance_to_seed < second_nearest) {
                second_nearest = distance_to_seed;
            }
        }
    }
    return vec3(nearest, second_nearest, identity);
}

vec2 hex_coord(vec2 point) {
    const vec2 SCALE = vec2(1.0, 1.7320508);
    vec2 first = mod(point, SCALE) - SCALE * 0.5;
    vec2 second = mod(point - SCALE * 0.5, SCALE) - SCALE * 0.5;
    return dot(first, first) < dot(second, second) ? first : second;
}

vec3 palette(float phase) {
    return 0.5 + 0.5 * cos(TAU * (phase + 0.426 + vec3(0.04, 0.37, 0.69)));
}

vec3 sample_cache(int index, vec2 uv) {
    return texture(history, vec3(mirror_repeat(uv),
                   float(CACHE_HISTORY_LAYER(index)))).rgb;
}

float history_fft(int index, float frequency) {
    int maximum_age = max(min(SIZE, spectrum_history_size) - 1, 0);
    int spectrum_age = min(index + 1, maximum_age);
    return texture(spectrum_history,
                   vec2(frequency, float(SPECTRUM_HISTORY_LAYER(spectrum_age)))).r;
}

vec2 concept_space(vec2 point, float age, vec3 old_audio,
                   float bass, float middle, float high) {
    vec2 q = point;
    float old_bass = old_audio.x;
    float old_mid = old_audio.y;
    float old_high = old_audio.z;
    q += vec2(sin(q.y * 11.0 + time_f), sin(q.x * 9.0 - time_f * 0.8)) * (0.018 + bass * 0.05);
    q *= 1.0 + sin((q.x + q.y) * 13.0 + age * 5.0) * old_mid * 0.035;
    return q;
}

float concept_field(vec2 q, float age, float bass, float middle, float high) {
    float terrain = noise_2d(q * 5.0) + 0.45 * noise_2d(q * 11.0);
    float contour = abs(fract(terrain * (6.0 + middle * 4.0) + age) - 0.5);
    return exp(-contour * (24.0 + high * 15.0));
}

vec3 blend_memory(vec3 memory, vec3 live, float field, float age, vec3 old_audio) {
    vec3 embossed = 0.5 + (memory - live) * (1.4 + field);
    return mix(memory, embossed * palette(age + old_audio.y), 0.44);
}

void main() {
    vec2 resolution = max(iResolution, vec2(1.0));
    vec2 aspect_scale = vec2(resolution.x / resolution.y, 1.0);
    vec2 center = iMouse.z > 0.0 ? iMouse.xy / resolution : vec2(0.5);
    vec2 point = (tc - center) * aspect_scale;
    float bass = max(texture(spectrum0, 0.045).r, amp_low);
    float middle = max(texture(spectrum0, 0.32).r, amp_mid);
    float high = max(texture(spectrum0, 0.82).r, amp_high);
    vec3 current_audio = vec3(bass, middle, high);

    vec2 live_q = concept_space(point, 0.0, current_audio, bass, middle, high);
    float live_field = concept_field(live_q, 0.0, bass, middle, high);
    vec3 live = texture(samp, mirror_repeat(live_q / aspect_scale + center)).rgb;
    vec3 accumulated = live * 1.2;
    float total_weight = 1.2;

    for (int index = 0; index < SIZE; ++index) {
        float age = float(index + 1) / float(max(SIZE, 1));
        vec3 old_audio = vec3(history_fft(index, 0.045),
                              history_fft(index, 0.32),
                              history_fft(index, 0.82));
        vec2 cache_q = concept_space(point, age, old_audio, bass, middle, high);
        float field = concept_field(cache_q, age, bass, middle, high);
        vec3 memory = sample_cache(index, cache_q / aspect_scale + center);
        vec3 treated = blend_memory(memory, live, field, age, old_audio);
        float weight = 1.0 / (1.0 + age * 5.0) * (0.55 + field * 0.65);
        accumulated += treated * weight;
        total_weight += weight;
    }

    vec3 result = accumulated / max(total_weight, 0.001);
    result += vec3(high, middle, bass) * live_field * 0.11;
    result = (result - 0.5) * (1.04 + amp_smooth * 0.18) + 0.5;
    color = vec4(clamp(result, 0.0, 1.0), texture(samp, tc).a);
}

