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

// Energy cache code: expanding reactor halos flood the scene with afterimages.
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
vec3 palette(float phase) { return 0.5 + 0.5 * cos(TAU * (phase + vec3(0.03, 0.29, 0.61))); }
vec3 sample_cache(int index, vec2 uv) { return texture(history, vec3(mirror_repeat(uv), float(CACHE_HISTORY_LAYER(index)))).rgb; }
float history_fft(int index, float frequency) {
    int maximum_age = max(min(SIZE, spectrum_history_size) - 1, 0);
    int age = min(index + 1, maximum_age);
    return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(age)))).r;
}

float halo_field(vec2 point, float bass, float middle, float high) {
    float radius = length(point);
    float angle = atan(point.y, point.x);
    float rings = sin(radius * (38.0 + bass * 20.0) - time_f * (7.0 + middle * 5.0));
    float spokes = sin(angle * (8.0 + floor(high * 6.0)) + time_f * 2.5 + radius * 8.0);
    return 1.0 - abs(rings * 0.7 + spokes * 0.3);
}

void main() {
    vec2 resolution = max(iResolution, vec2(1.0));
    vec2 aspect = vec2(resolution.x / resolution.y, 1.0);
    vec2 center = vec2(0.5) + vec2(sin(time_f * 0.31), cos(time_f * 0.27)) * 0.07;
    vec2 point = (tc - center) * aspect;
    float bass = texture(spectrum0, 0.03).r;
    float middle = texture(spectrum0, 0.25).r;
    float high = texture(spectrum0, 0.69).r;
    float radius = max(length(point), 0.003);
    float halo = halo_field(point, bass, middle, high);
    vec2 radial = point / radius;
    vec2 warp = radial * sin(radius * 45.0 - time_f * 7.0) * halo * (0.018 + bass * 0.05);
    vec3 live = texture(samp, mirror_repeat(tc + warp / aspect)).rgb;
    live *= 0.72 + palette(radius * 0.7 - time_f * 0.11) * 0.82;
    live += palette(halo + radius - time_f * 0.16) * pow(halo, 5.0) * (0.9 + high * 2.4);

    vec3 accumulated = live * 1.1;
    float total_weight = 1.1;
    for (int index = 0; index < SIZE; ++index) {
        float generation = float(index + 1);
        float age = generation / float(max(SIZE, 1));
        vec3 old_audio = vec3(history_fft(index, 0.03), history_fft(index, 0.25), history_fft(index, 0.69));
        float scale = 1.0 - age * (0.13 + old_audio.x * 0.1);
        float angle = age * (0.12 + old_audio.z * 0.42) * sin(time_f * 0.4 + generation);
        float cosine = cos(angle);
        float sine = sin(angle);
        vec2 cache_point = mat2(cosine, -sine, sine, cosine) * point * scale;
        vec3 memory = sample_cache(index, cache_point / aspect + center);
        memory *= palette(age * 0.75 + old_audio.y * 0.5 + radius * 0.15);
        float weight = pow(0.77, generation) * (0.85 + old_audio.x * 0.55);
        accumulated += memory * weight;
        total_weight += weight;
    }
    vec3 result = accumulated / total_weight;
    result += palette(radius * 0.6 + time_f * 0.05) * pow(halo, 7.0) * (0.5 + amp_peak * 1.4);
    result = result / (0.74 + result);
    result = (result - 0.5) * (1.25 + amp_smooth * 0.24) + 0.5;
    color = vec4(clamp(result, 0.0, 1.0), 1.0);
}
