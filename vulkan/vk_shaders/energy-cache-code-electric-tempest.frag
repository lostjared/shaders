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

// Energy cache code: room-filling electric interference with audio-aged lightning trails.
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

vec2 mirror_repeat(vec2 point) {
    return 1.0 - abs(mod(point, 2.0) - 1.0);
}

vec3 palette(float phase) {
    return 0.5 + 0.5 * cos(TAU * (phase + vec3(0.02, 0.31, 0.67)));
}

vec3 sample_cache(int index, vec2 uv) {
    return texture(history, vec3(mirror_repeat(uv), float(CACHE_HISTORY_LAYER(index)))).rgb;
}

float history_fft(int index, float frequency) {
    int maximum_age = max(min(SIZE, spectrum_history_size) - 1, 0);
    int age = min(index + 1, maximum_age);
    return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(age)))).r;
}

float tempest(vec2 point, float bass, float high) {
    float first = sin(length(point - vec2(sin(time_f * 0.41), cos(time_f * 0.33)) * 0.38) * (25.0 + bass * 18.0) - time_f * 7.0);
    float second = sin(length(point + vec2(cos(time_f * 0.29), sin(time_f * 0.47)) * 0.42) * (31.0 + high * 15.0) + time_f * 5.0);
    float crossing = sin(point.x * 42.0 + sin(point.y * 13.0 - time_f * 4.0) * 4.0);
    return (first + second + crossing) / 3.0;
}

void main() {
    vec2 resolution = max(iResolution, vec2(1.0));
    vec2 aspect = vec2(resolution.x / resolution.y, 1.0);
    vec2 point = (tc - 0.5) * aspect;
    float bass = texture(spectrum0, 0.035).r;
    float middle = texture(spectrum0, 0.28).r;
    float high = texture(spectrum0, 0.76).r;
    float field = tempest(point, bass, high);
    vec2 distortion = vec2(field, tempest(point.yx + 0.17, middle, bass)) * (0.025 + bass * 0.045);
    vec3 live = texture(samp, mirror_repeat(tc + distortion)).rgb;
    float bolt = pow(1.0 - abs(field), 14.0);
    live += palette(field * 0.3 + time_f * 0.08) * bolt * (1.2 + high * 3.0);

    vec3 accumulated = live * 1.25;
    float total_weight = 1.25;
    for (int index = 0; index < SIZE; ++index) {
        float generation = float(index + 1);
        float age = generation / float(max(SIZE, 1));
        vec3 old_audio = vec3(history_fft(index, 0.035), history_fft(index, 0.28), history_fft(index, 0.76));
        float angle = generation * (0.018 + old_audio.z * 0.11) * sin(time_f * 0.23 + age * TAU);
        float cosine = cos(angle);
        float sine = sin(angle);
        mat2 rotation = mat2(cosine, -sine, sine, cosine);
        vec2 cache_point = rotation * point * (1.0 - age * (0.055 + old_audio.x * 0.09));
        cache_point += distortion * generation * 0.28 + vec2(sine, cosine) * old_audio.y * 0.018;
        vec2 cache_uv = cache_point / aspect + 0.5;
        vec3 memory = sample_cache(index, cache_uv) * palette(age * 0.62 + old_audio.y * 0.4);
        float weight = exp(-age * (1.8 - amp_smooth * 0.4));
        accumulated += memory * weight;
        total_weight += weight;
    }

    vec3 result = accumulated / total_weight;
    result += palette(length(point) - time_f * 0.12) * bolt * (0.45 + amp_peak);
    result = (result - 0.5) * (1.25 + amp_smooth * 0.3) + 0.5;
    result = mix(result, 1.0 - result, smoothstep(0.88, 1.0, amp_peak));
    color = vec4(clamp(result, 0.0, 1.0), 1.0);
}
