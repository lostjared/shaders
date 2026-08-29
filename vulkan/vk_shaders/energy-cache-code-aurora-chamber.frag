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

// Energy cache code: aurora curtains and cache echoes occupy the entire frame.
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
vec3 palette(float phase) { return 0.5 + 0.5 * cos(TAU * (phase + vec3(0.16, 0.49, 0.82))); }
vec3 sample_cache(int index, vec2 uv) { return texture(history, vec3(mirror_repeat(uv), float(CACHE_HISTORY_LAYER(index)))).rgb; }
float history_fft(int index, float frequency) {
    int maximum_age = max(min(SIZE, spectrum_history_size) - 1, 0);
    int age = min(index + 1, maximum_age);
    return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(age)))).r;
}

float aurora(vec2 point, float bass, float middle, float high) {
    float curtain_a = sin(point.x * (9.0 + middle * 6.0) + sin(point.y * 5.0 + time_f) * 2.0 - time_f * 2.2);
    float curtain_b = sin(point.x * 17.0 - point.y * 7.0 + cos(point.x * 4.0 - time_f) * 3.0 + time_f * 3.1);
    float curtain_c = sin((point.x + point.y) * (12.0 + high * 8.0) - time_f * 4.0);
    return (curtain_a + curtain_b + curtain_c) / 3.0;
}

void main() {
    vec2 resolution = max(iResolution, vec2(1.0));
    vec2 aspect = vec2(resolution.x / resolution.y, 1.0);
    vec2 point = (tc - 0.5) * aspect;
    float bass = texture(spectrum0, 0.045).r;
    float middle = texture(spectrum0, 0.34).r;
    float high = texture(spectrum0, 0.84).r;
    float flow = aurora(point, bass, middle, high);
    float curtain = pow(1.0 - abs(flow), 4.0);
    vec2 warp = vec2(flow, aurora(point.yx * 1.13, high, bass, middle)) * (0.018 + middle * 0.05);
    vec3 live = texture(samp, mirror_repeat(tc + warp)).rgb;
    live *= 0.68 + palette(flow * 0.28 + time_f * 0.07) * 0.95;
    live += palette(point.x * 0.18 + point.y * 0.3 - time_f * 0.1) * curtain * (0.7 + high * 2.3);

    vec3 accumulated = live * 1.2;
    float total_weight = 1.2;
    for (int index = 0; index < SIZE; ++index) {
        float generation = float(index + 1);
        float age = generation / float(max(SIZE, 1));
        vec3 old_audio = vec3(history_fft(index, 0.045), history_fft(index, 0.34), history_fft(index, 0.84));
        vec2 cache_point = point;
        cache_point.x += sin(cache_point.y * 8.0 + time_f * 0.8 + generation) * age * (0.04 + old_audio.y * 0.08);
        cache_point.y += cos(cache_point.x * 11.0 - time_f + generation * 0.7) * old_audio.z * 0.035;
        cache_point *= 1.0 - age * (0.035 + old_audio.x * 0.045);
        vec3 memory = sample_cache(index, cache_point / aspect + 0.5);
        memory *= palette(old_audio.y * 0.55 + age * 0.8 + flow * 0.12);
        float weight = exp(-age * 1.65) * (0.75 + old_audio.z * 0.4);
        accumulated += memory * weight;
        total_weight += weight;
    }
    vec3 result = accumulated / total_weight;
    result += palette(flow + time_f * 0.04) * curtain * (0.35 + amp_peak);
    result = result / (0.7 + result);
    result = (result - 0.5) * (1.18 + amp_smooth * 0.28) + 0.5;
    color = vec4(clamp(result, 0.0, 1.0), 1.0);
}
