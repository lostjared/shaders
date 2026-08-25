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

// Spectral glass cells refract video while cached color leaks through the seams.
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
    return fract(sin(dot(point, vec2(127.1, 311.7))) * 43758.5453);
}

vec3 cell_data(vec2 point) {
    vec2 base = floor(point);
    vec2 part = fract(point);
    float nearest = 8.0;
    float second_nearest = 8.0;
    float identity = 0.0;
    for (int y = -1; y <= 1; ++y) {
        for (int x = -1; x <= 1; ++x) {
            vec2 offset = vec2(float(x), float(y));
            vec2 seed = vec2(hash_21(base + offset),
                             hash_21(base + offset + 17.4));
            float distance_to_seed = length(offset + seed - part);
            if (distance_to_seed < nearest) {
                second_nearest = nearest;
                nearest = distance_to_seed;
                identity = hash_21(base + offset + 31.7);
            } else if (distance_to_seed < second_nearest) {
                second_nearest = distance_to_seed;
            }
        }
    }
    return vec3(nearest, second_nearest, identity);
}

vec3 palette(float phase) {
    return 0.5 + 0.5 * cos(TAU * (phase + vec3(0.0, 0.29, 0.63)));
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
    float middle = max(texture(spectrum0, 0.33).r, amp_mid);
    float treble = max(texture(spectrum0, 0.83).r, amp_high);
    vec2 glass_point = rotate_2d(time_f * 0.035 + middle * 0.16) * point *
                       (7.0 + treble * 4.0);
    vec3 cell = cell_data(glass_point);
    float seam = exp(-abs(cell.y - cell.x) * (45.0 + treble * 30.0));
    vec2 refraction = normalize(fract(glass_point) - 0.5 + vec2(0.0001)) *
                      (cell.x - 0.25) * (0.025 + bass * 0.04);
    vec2 live_uv = tc + refraction;
    vec3 live = texture(samp, mirror_repeat(live_uv)).rgb;
    live *= 0.65 + palette(cell.z + time_f * 0.03) * 0.7;
    live += palette(cell.z - time_f * 0.05) * seam * (0.2 + treble * 0.38);

    vec3 accumulated = live * 1.2;
    float total_weight = 1.2;
    for (int index = 0; index < SIZE; ++index) {
        float age = float(index + 1) / float(max(SIZE, 1));
        float old_bass = history_fft(index, 0.045);
        float old_middle = history_fft(index, 0.33);
        float old_treble = history_fft(index, 0.83);
        vec2 cache_point = rotate_2d(age * (0.17 + old_middle * 0.75)) * point;
        cache_point *= 1.0 - age * (0.09 + old_bass * 0.07);
        vec2 cache_uv = cache_point / vec2(aspect, 1.0) + center;
        cache_uv += refraction * (0.35 + age * old_treble);
        vec3 memory = sample_cache(index, cache_uv);
        memory *= 0.62 + palette(cell.z + age + old_middle) * 0.66;
        memory += palette(age + cell.z) * seam * old_treble * 0.12;
        float weight = exp(-age * 2.3) * (0.68 + old_bass * 0.55);
        accumulated += memory * weight;
        total_weight += weight;
    }

    vec3 result = accumulated / total_weight;
    result += palette(cell.z + 0.5) * seam * amp_peak * 0.2;
    result = (result - 0.5) * (1.1 + amp_smooth * 0.3) + 0.5;
    color = vec4(clamp(result, 0.0, 1.0), texture(samp, tc).a);
}
