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

// A chromatic gravity well stratifies cached frames by frequency age.
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
    return 0.5 + 0.5 * cos(TAU * (phase + vec3(0.0, 0.36, 0.7)));
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
    float bass = max(texture(spectrum0, 0.03).r, amp_low);
    float middle = max(texture(spectrum0, 0.25).r, amp_mid);
    float treble = max(texture(spectrum0, 0.74).r, amp_high);
    float radius = length(point) + 0.0001;
    vec2 radial = point / radius;
    vec2 tangent = vec2(-radial.y, radial.x);
    float rings = sin(radius * (38.0 + bass * 24.0) - time_f * 7.0);
    vec2 live_point = rotate_2d((0.13 + middle * 0.5) /
                      (0.18 + radius) + time_f * 0.04) * point;
    live_point += radial * rings * (0.012 + bass * 0.035);
    vec2 live_uv = live_point / vec2(aspect, 1.0) + center;
    vec3 live;
    float split = 0.004 + treble * 0.024;
    live.r = texture(samp, mirror_repeat(live_uv + tangent * split)).r;
    live.g = texture(samp, mirror_repeat(live_uv)).g;
    live.b = texture(samp, mirror_repeat(live_uv - tangent * split)).b;
    live += palette(radius * 2.0 - time_f * 0.08) *
            pow(max(rings, 0.0), 8.0) * (0.14 + bass * 0.28);

    vec3 accumulated = live * 1.25;
    float total_weight = 1.25;
    for (int index = 0; index < SIZE; ++index) {
        float age = float(index + 1) / float(max(SIZE, 1));
        float old_bass = history_fft(index, 0.03);
        float old_mid = history_fft(index, 0.25);
        float old_high = history_fft(index, 0.74);
        vec2 cache_point = point;
        cache_point = rotate_2d(age * (0.3 + old_mid * 1.4)) * cache_point;
        cache_point *= 1.0 - age * (0.18 + old_bass * 0.1);
        cache_point += tangent * sin(radius * 28.0 - age * 16.0) *
                       old_high * 0.035;
        vec2 cache_uv = cache_point / vec2(aspect, 1.0) + center;
        vec3 memory = sample_cache(index, cache_uv);
        vec3 shifted = index % 3 == 0 ? memory.gbr :
                       (index % 3 == 1 ? memory.brg : memory.rgb);
        memory = mix(memory, shifted, 0.28 + old_high * 0.38);
        memory *= 0.66 + palette(age + radius) * 0.56;
        float weight = exp(-age * 2.35) * (0.7 + old_bass * 0.6);
        accumulated += memory * weight;
        total_weight += weight;
    }

    vec3 result = accumulated / total_weight;
    result += palette(radius - time_f * 0.06) * amp_peak *
              pow(max(rings, 0.0), 10.0) * 0.24;
    result = (result - 0.5) * (1.12 + amp_smooth * 0.3) + 0.5;
    color = vec4(clamp(result, 0.0, 1.0), texture(samp, tc).a);
}
