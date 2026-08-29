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

// Energy cache code: a photon tunnel fills depth with accelerating echoes.
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
vec3 palette(float phase) { return 0.5 + 0.5 * cos(TAU * (phase + vec3(0.04, 0.34, 0.68))); }
vec3 sample_cache(int index, vec2 uv) { return texture(history, vec3(mirror_repeat(uv), float(CACHE_HISTORY_LAYER(index)))).rgb; }
float history_fft(int index, float frequency) {
    int maximum_age = max(min(SIZE, spectrum_history_size) - 1, 0);
    int age = min(index + 1, maximum_age);
    return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(age)))).r;
}

float photon_field(vec2 point, float bass, float middle, float high) {
    float radius = max(length(point), 0.01);
    float angle = atan(point.y, point.x);
    float depth = 1.0 / radius;
    float radial = sin(depth * (3.0 + bass * 2.0) - time_f * 7.0);
    float sectors = sin(angle * (10.0 + floor(high * 7.0)) + depth + time_f * 2.0);
    return 1.0 - abs(radial * 0.68 + sectors * 0.32);
}

void main() {
    vec2 resolution = max(iResolution, vec2(1.0));
    vec2 aspect = vec2(resolution.x / resolution.y, 1.0);
    vec2 center = vec2(0.5) + vec2(sin(time_f * 0.37), cos(time_f * 0.29)) * 0.055;
    vec2 point = (tc - center) * aspect;
    float bass = texture(spectrum0, 0.035).r;
    float middle = texture(spectrum0, 0.26).r;
    float high = texture(spectrum0, 0.74).r;
    float radius = max(length(point), 0.01);
    float photons = photon_field(point, bass, middle, high);
    vec2 warp = point / radius * photons * (0.018 + bass * 0.06);
    vec3 live = texture(samp, mirror_repeat(tc - warp / aspect)).rgb;
    live *= 0.66 + palette(1.0 / radius * 0.08 - time_f * 0.1) * 0.95;
    live += palette(photons + time_f * 0.13) * pow(photons, 5.0) * (0.9 + high * 2.6);

    vec3 accumulated = live * 1.18;
    float total_weight = 1.18;
    for (int index = 0; index < SIZE; ++index) {
        float generation = float(index + 1);
        float age = generation / float(max(SIZE, 1));
        vec3 old_audio = vec3(history_fft(index, 0.035), history_fft(index, 0.26), history_fft(index, 0.74));
        float angle = age * (0.08 + old_audio.z * 0.38);
        float cosine = cos(angle);
        float sine = sin(angle);
        vec2 cache_point = mat2(cosine, -sine, sine, cosine) * point;
        cache_point *= 1.0 - age * (0.15 + old_audio.x * 0.12);
        vec3 memory = sample_cache(index, cache_point / aspect + center);
        memory *= palette(age * 0.9 + old_audio.y * 0.45 + 1.0 / radius * 0.025);
        float weight = pow(0.78, generation) * (0.8 + old_audio.x * 0.5);
        accumulated += memory * weight;
        total_weight += weight;
    }
    vec3 result = accumulated / total_weight;
    result += palette(1.0 / radius * 0.06 - time_f * 0.08) * pow(photons, 7.0) * (0.55 + amp_peak * 1.5);
    result = result / (0.7 + result);
    result = (result - 0.5) * (1.28 + amp_smooth * 0.27) + 0.5;
    color = vec4(clamp(result, 0.0, 1.0), 1.0);
}
