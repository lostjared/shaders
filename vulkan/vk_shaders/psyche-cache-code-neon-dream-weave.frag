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

// Interlaced neon waves braid live video with spectral memory.
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

vec3 palette(float phase) {
    return 0.5 + 0.5 * cos(TAU * (phase + vec3(0.08, 0.45, 0.79)));
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

float weave_field(vec2 point, float bass, float middle, float treble,
                  float age) {
    float horizontal = sin(point.x * (17.0 + treble * 9.0) +
                           sin(point.y * 8.0 - time_f * 2.0 - age * 7.0) *
                           (3.0 + bass * 5.0));
    float vertical = cos(point.y * (19.0 + middle * 8.0) +
                         sin(point.x * 7.0 + time_f * 1.7 + age * 9.0) *
                         (3.0 + treble * 4.0));
    return horizontal * vertical;
}

void main() {
    vec2 resolution = max(iResolution, vec2(1.0));
    float aspect = resolution.x / resolution.y;
    vec2 center = iMouse.z > 0.0 ? iMouse.xy / resolution : vec2(0.5);
    vec2 point = (tc - center) * vec2(aspect, 1.0);
    float bass = max(texture(spectrum0, 0.055).r, amp_low);
    float middle = max(texture(spectrum0, 0.38).r, amp_mid);
    float treble = max(texture(spectrum0, 0.86).r, amp_high);
    float field = weave_field(point, bass, middle, treble, 0.0);
    vec2 flow = vec2(cos(field * TAU), sin(field * TAU));
    vec2 live_uv = tc + flow * field * (0.012 + bass * 0.04);
    vec3 live = texture(samp, mirror_repeat(live_uv)).rgb;
    float threads = pow(1.0 - abs(field), 9.0);
    live += palette(field * 0.35 + time_f * 0.05) * threads *
            (0.18 + treble * 0.38);

    vec3 accumulated = live * 1.2;
    float total_weight = 1.2;
    for (int index = 0; index < SIZE; ++index) {
        float age = float(index + 1) / float(max(SIZE, 1));
        float old_bass = history_fft(index, 0.055);
        float old_middle = history_fft(index, 0.38);
        float old_treble = history_fft(index, 0.86);
        float old_field = weave_field(point, old_bass, old_middle,
                                      old_treble, age);
        vec2 cache_uv = tc - center;
        cache_uv = rotate_2d((old_middle - old_treble) * age * 0.7) * cache_uv;
        cache_uv *= 1.0 - age * (0.07 + old_bass * 0.08);
        cache_uv += vec2(old_field, -old_field) * age * 0.025;
        cache_uv += center;
        vec3 memory = sample_cache(index, cache_uv);
        memory *= 0.65 + palette(old_field * 0.3 + age) * 0.62;
        float old_threads = pow(1.0 - abs(old_field), 6.0);
        memory += palette(age - time_f * 0.03) * old_threads * 0.12;
        float weight = exp(-age * 2.5) * (0.7 + old_middle * 0.5);
        accumulated += memory * weight;
        total_weight += weight;
    }

    vec3 result = accumulated / total_weight;
    result = mix(result, result.rbg, smoothstep(0.88, 1.0, amp_peak) * 0.65);
    result = (result - 0.5) * (1.1 + amp_smooth * 0.28) + 0.5;
    color = vec4(clamp(result, 0.0, 1.0), texture(samp, tc).a);
}
