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

// Energy cache code: tall plasma columns turn the image into a resonant chamber.
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
vec3 palette(float phase) { return 0.5 + 0.5 * cos(TAU * (phase + vec3(0.00, 0.24, 0.58))); }
vec3 sample_cache(int index, vec2 uv) { return texture(history, vec3(mirror_repeat(uv), float(CACHE_HISTORY_LAYER(index)))).rgb; }
float history_fft(int index, float frequency) {
    int maximum_age = max(min(SIZE, spectrum_history_size) - 1, 0);
    int age = min(index + 1, maximum_age);
    return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(age)))).r;
}

float plasma_arches(vec2 point, float bass, float middle, float high) {
    float columns = abs(sin(point.x * (13.0 + middle * 8.0) + sin(point.y * 7.0 - time_f * 2.2) * 1.8));
    float ceiling = abs(sin(length(point * vec2(0.75, 1.8)) * (18.0 + bass * 9.0) - time_f * 4.0));
    float current = abs(sin((point.x + point.y) * 27.0 + time_f * 6.0 + high * 5.0));
    return 1.0 - min(columns * ceiling * current * 2.4, 1.0);
}

void main() {
    vec2 resolution = max(iResolution, vec2(1.0));
    vec2 aspect = vec2(resolution.x / resolution.y, 1.0);
    vec2 point = (tc - 0.5) * aspect;
    float bass = texture(spectrum0, 0.04).r;
    float middle = texture(spectrum0, 0.31).r;
    float high = texture(spectrum0, 0.72).r;
    float energy = plasma_arches(point, bass, middle, high);
    vec2 warp = vec2(sin(point.y * 19.0 - time_f * 3.0), cos(point.x * 17.0 + time_f * 2.0)) * energy * (0.012 + bass * 0.035);
    vec3 live = texture(samp, mirror_repeat(tc + warp)).rgb;
    live = live * (0.7 + palette(point.y * 0.4 + time_f * 0.1) * 0.8);
    live += palette(point.x * 0.25 - time_f * 0.16) * pow(energy, 4.0) * (0.8 + high * 2.5);

    vec3 accumulated = live * 1.15;
    float total_weight = 1.15;
    for (int index = 0; index < SIZE; ++index) {
        float generation = float(index + 1);
        float age = generation / float(max(SIZE, 1));
        vec3 old_audio = vec3(history_fft(index, 0.04), history_fft(index, 0.31), history_fft(index, 0.72));
        vec2 cache_point = point;
        cache_point.x *= 1.0 - age * (0.08 + old_audio.x * 0.08);
        cache_point.y += sin(cache_point.x * 12.0 + generation + time_f) * old_audio.y * 0.045;
        cache_point.y *= 1.0 + age * 0.035;
        vec3 memory = sample_cache(index, cache_point / aspect + 0.5 + warp * age);
        memory *= palette(age + old_audio.z * 0.35 + point.y * 0.12);
        float weight = exp(-age * 2.0) * (0.75 + old_audio.x * 0.5);
        accumulated += memory * weight;
        total_weight += weight;
    }
    vec3 result = accumulated / total_weight;
    result += palette(energy + time_f * 0.05) * energy * energy * (0.3 + amp_peak);
    result = result / (0.72 + result);
    result = (result - 0.5) * (1.2 + amp_smooth * 0.25) + 0.5;
    color = vec4(clamp(result, 0.0, 1.0), 1.0);
}
