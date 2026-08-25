#version 450

layout(set = 0, binding = 1, std140) uniform SpriteExtended {
    vec4 mouse;
    vec4 u0;
    vec4 u1;
    vec4 u2;
    vec4 u3;
    vec4 custom_uniforms[16];
    vec4 audio_bands;
    vec4 audio_history;
} ext;
#define amp_high ext.audio_bands.z
#define amp_low ext.audio_bands.x
#define amp_mid ext.audio_bands.y
#define amp_peak ext.u2.w
#define amp_smooth ext.u3.w
#define history_head int(ext.u3.x)
#define iMouse ext.mouse
#define iResolution ext.u0.zw
#define spectrum_history_head int(ext.audio_history.x)
#define spectrum_history_size int(ext.audio_history.y)
#define time_f ext.u2.y

// Codex cache concept 004: topographic memory.
// Remixes repository cache, spectrum-history, coordinate-fold, and palette idioms.
layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;
layout(set = 0, binding = 2) uniform sampler2DArray history;

#ifndef SIZE
#define SIZE 8
#endif
#ifndef CACHE_HISTORY_LAYER
#define CACHE_HISTORY_LAYER(index) ((history_head + (index)) % SIZE)
#endif
layout(set = 0, binding = 3) uniform sampler1D spectrum0;
layout(set = 0, binding = 4) uniform sampler1DArray spectrum_history;


#ifndef SPECTRUM_HISTORY_LAYER
#define SPECTRUM_HISTORY_LAYER(index) ((spectrum_history_head - ((index) % max(spectrum_history_size, 1)) + max(spectrum_history_size, 1)) % max(spectrum_history_size, 1))
#endif









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
    return 0.5 + 0.5 * cos(TAU * (phase + 0.411 + vec3(0.04, 0.37, 0.69)));
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
    float flow = noise_2d(q * 4.0 + vec2(time_f * 0.13, -time_f * 0.09));
    float angle = TAU * flow + old_mid * 2.0 + age;
    q += vec2(cos(angle), sin(angle)) * (0.025 + old_bass * 0.055) * (0.4 + age);
    return q;
}

float concept_field(vec2 q, float age, float bass, float middle, float high) {
    float terrain = noise_2d(q * 5.0) + 0.45 * noise_2d(q * 11.0);
    float contour = abs(fract(terrain * (6.0 + middle * 4.0) + age) - 0.5);
    return exp(-contour * (24.0 + high * 15.0));
}

vec3 blend_memory(vec3 memory, vec3 live, float field, float age, vec3 old_audio) {
    return mix(abs(memory - live), memory * (0.7 + palette(age + field) * 0.55), 0.58);
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
        float weight = exp(-age * 1.9) * (0.42 + field * 0.38 + old_audio.z * 0.35);
        accumulated += treated * weight;
        total_weight += weight;
    }

    vec3 result = accumulated / max(total_weight, 0.001);
    result = mix(result, result.gbr, live_field * high * 0.24);
    result = (result - 0.5) * (1.04 + amp_smooth * 0.18) + 0.5;
    color = vec4(clamp(result, 0.0, 1.0), texture(samp, tc).a);
}

