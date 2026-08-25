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
#define amp_peak ext.u2.w
#define amp_smooth ext.u3.w
#define history_head int(ext.u3.x)
#define iResolution ext.u0.zw
#define spectrum_history_head int(ext.audio_history.x)
#define spectrum_history_size int(ext.audio_history.y)
#define time_f ext.u2.y

// Energy cache code: crossed lightning rails connect every surface.
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

vec2 mirror_repeat(vec2 point) { return 1.0 - abs(mod(point, 2.0) - 1.0); }
float hash_21(vec2 point) { return fract(sin(dot(point, vec2(41.7, 289.1))) * 43758.5453123); }
vec3 palette(float phase) { return 0.5 + 0.5 * cos(TAU * (phase + vec3(0.10, 0.36, 0.70))); }
vec3 sample_cache(int index, vec2 uv) { return texture(history, vec3(mirror_repeat(uv), float(CACHE_HISTORY_LAYER(index)))).rgb; }
float history_fft(int index, float frequency) {
    int maximum_age = max(min(SIZE, spectrum_history_size) - 1, 0);
    int age = min(index + 1, maximum_age);
    return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(age)))).r;
}

float lattice(vec2 point, float bass, float middle, float high) {
    vec2 grid = abs(fract(point * (8.0 + middle * 5.0)) - 0.5);
    float rails = min(grid.x, grid.y);
    float diagonal = abs(fract((point.x + point.y) * (6.0 + high * 4.0) + time_f * 0.8) - 0.5);
    float jitter = hash_21(floor(point * 18.0) + floor(time_f * 9.0)) * bass * 0.09;
    return exp(-min(rails, diagonal) * (65.0 + high * 30.0) + jitter * 18.0);
}

void main() {
    vec2 resolution = max(iResolution, vec2(1.0));
    vec2 aspect = vec2(resolution.x / resolution.y, 1.0);
    vec2 point = (tc - 0.5) * aspect;
    float bass = texture(spectrum0, 0.04).r;
    float middle = texture(spectrum0, 0.3).r;
    float high = texture(spectrum0, 0.8).r;
    float grid_energy = lattice(point + vec2(sin(time_f), cos(time_f * 0.7)) * 0.02, bass, middle, high);
    vec2 warp = vec2(sin(point.y * 37.0 - time_f * 8.0), cos(point.x * 33.0 + time_f * 7.0)) * grid_energy * (0.02 + bass * 0.055);
    vec3 live = texture(samp, mirror_repeat(tc + warp)).rgb;
    live *= 0.76 + palette(point.x * 0.2 - point.y * 0.15 + time_f * 0.08) * 0.72;
    live += palette(grid_energy + time_f * 0.14) * grid_energy * (0.8 + high * 3.0);

    vec3 accumulated = live;
    float total_weight = 1.0;
    for (int index = 0; index < SIZE; ++index) {
        float generation = float(index + 1);
        float age = generation / float(max(SIZE, 1));
        vec3 old_audio = vec3(history_fft(index, 0.04), history_fft(index, 0.3), history_fft(index, 0.8));
        vec2 cache_point = point * (1.0 - age * (0.06 + old_audio.x * 0.07));
        cache_point += vec2(hash_21(vec2(generation, floor(time_f * 6.0))), hash_21(vec2(floor(time_f * 6.0), generation))) * old_audio.z * 0.07 - old_audio.z * 0.035;
        vec3 memory = sample_cache(index, cache_point / aspect + 0.5);
        float old_grid = lattice(cache_point, old_audio.x, old_audio.y, old_audio.z);
        memory *= palette(age * 0.8 + old_audio.z * 0.3 + old_grid * 0.2);
        float weight = pow(0.75, generation) * (0.8 + old_grid * 0.7);
        accumulated += memory * weight;
        total_weight += weight;
    }
    vec3 result = accumulated / total_weight;
    result += palette(point.y - time_f * 0.1) * grid_energy * (0.55 + amp_peak * 1.5);
    result = (result - 0.5) * (1.32 + amp_smooth * 0.3) + 0.5;
    result = mix(result, vec3(1.0) - result, smoothstep(0.9, 1.0, amp_peak));
    color = vec4(clamp(result, 0.0, 1.0), 1.0);
}
