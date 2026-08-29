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

// Energy cache code: quantum wavefronts surge with peak inversion flashes.
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
vec3 palette(float phase) { return 0.5 + 0.5 * cos(TAU * (phase + vec3(0.01, 0.28, 0.64))); }
vec3 sample_cache(int index, vec2 uv) { return texture(history, vec3(mirror_repeat(uv), float(CACHE_HISTORY_LAYER(index)))).rgb; }
float history_fft(int index, float frequency) {
    int maximum_age = max(min(SIZE, spectrum_history_size) - 1, 0);
    int age = min(index + 1, maximum_age);
    return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(age)))).r;
}

float surge(vec2 point, float bass, float middle, float high) {
    vec2 source_a = vec2(sin(time_f * 0.43), cos(time_f * 0.37)) * 0.31;
    vec2 source_b = vec2(cos(time_f * 0.29), -sin(time_f * 0.53)) * 0.39;
    vec2 source_c = vec2(-cos(time_f * 0.61), sin(time_f * 0.31)) * 0.26;
    float a = sin(length(point - source_a) * (24.0 + bass * 16.0) - time_f * 6.0);
    float b = sin(length(point - source_b) * (29.0 + middle * 14.0) - time_f * 5.0);
    float c = sin(length(point - source_c) * (35.0 + high * 12.0) - time_f * 8.0);
    return (a + b + c) / 3.0;
}

void main() {
    vec2 resolution = max(iResolution, vec2(1.0));
    vec2 aspect = vec2(resolution.x / resolution.y, 1.0);
    vec2 point = (tc - 0.5) * aspect;
    float bass = texture(spectrum0, 0.03).r;
    float middle = texture(spectrum0, 0.23).r;
    float high = texture(spectrum0, 0.67).r;
    float wave = surge(point, bass, middle, high);
    float crest = pow(max(wave, 0.0), 6.0) + pow(max(-wave, 0.0), 9.0) * 0.55;
    vec2 warp = vec2(wave, surge(point.yx * 1.07 + 0.19, high, bass, middle)) * (0.035 + bass * 0.06);
    vec3 live;
    float chroma = crest * (0.018 + high * 0.045);
    live.r = texture(samp, mirror_repeat(tc + warp + vec2(chroma, 0.0))).r;
    live.g = texture(samp, mirror_repeat(tc + warp)).g;
    live.b = texture(samp, mirror_repeat(tc + warp - vec2(chroma, 0.0))).b;
    live *= 0.68 + palette(wave * 0.3 + time_f * 0.08) * 0.95;
    live += palette(length(point) * 0.5 - time_f * 0.17) * crest * (0.9 + high * 2.7);

    vec3 accumulated = live * 1.2;
    float total_weight = 1.2;
    for (int index = 0; index < SIZE; ++index) {
        float generation = float(index + 1);
        float age = generation / float(max(SIZE, 1));
        vec3 old_audio = vec3(history_fft(index, 0.03), history_fft(index, 0.23), history_fft(index, 0.67));
        float angle = generation * (0.02 + old_audio.z * 0.1) * sin(time_f * 0.35 + age * TAU);
        float cosine = cos(angle);
        float sine = sin(angle);
        vec2 cache_point = mat2(cosine, -sine, sine, cosine) * point;
        cache_point *= 1.0 - age * (0.09 + old_audio.x * 0.11);
        cache_point += warp * age * (0.8 + old_audio.y);
        vec3 memory = sample_cache(index, cache_point / aspect + 0.5);
        memory *= palette(age * 0.7 + old_audio.y * 0.5 - time_f * 0.03);
        float weight = pow(0.8, generation) * (0.72 + old_audio.x * 0.55);
        accumulated += memory * weight;
        total_weight += weight;
    }
    vec3 result = accumulated / total_weight;
    result += palette(wave + time_f * 0.09) * crest * (0.4 + amp_peak * 1.6);
    result = (result - 0.5) * (1.31 + amp_smooth * 0.3) + 0.5;
    result = mix(result, vec3(1.0) - result, smoothstep(0.86, 1.0, amp_peak));
    color = vec4(clamp(result, 0.0, 1.0), 1.0);
}
