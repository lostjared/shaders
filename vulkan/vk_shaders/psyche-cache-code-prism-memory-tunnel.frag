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

// Prismatic FFT bands corkscrew cached frames into a deep tunnel.
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
    return 0.5 + 0.5 * cos(TAU * (phase + vec3(0.04, 0.38, 0.71)));
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
    float middle = max(texture(spectrum0, 0.22).r, amp_mid);
    float treble = max(texture(spectrum0, 0.66).r, amp_high);
    float radius = length(point) + 0.015;
    float angle = atan(point.y, point.x);
    float tunnel = 0.18 / radius + time_f * (0.14 + bass * 0.15);
    float spiral_angle = angle + tunnel * (1.6 + middle * 2.0);
    float prism = abs(mod(spiral_angle / TAU * (7.0 + floor(treble * 6.0)) +
                      0.5, 1.0) - 0.5);
    vec2 tunnel_point = vec2(cos(spiral_angle), sin(spiral_angle)) *
                        fract(tunnel) * (0.72 + bass * 0.08);
    vec2 live_uv = tunnel_point / vec2(aspect, 1.0) + center;
    vec2 tangent = vec2(-sin(spiral_angle), cos(spiral_angle));
    float split = 0.003 + treble * 0.02;
    vec3 live;
    live.r = texture(samp, mirror_repeat(live_uv + tangent * split)).r;
    live.g = texture(samp, mirror_repeat(live_uv)).g;
    live.b = texture(samp, mirror_repeat(live_uv - tangent * split)).b;
    float edge = exp(-prism * 24.0);
    live += palette(spiral_angle / TAU + tunnel) * edge *
            (0.12 + treble * 0.34);

    vec3 accumulated = live * 1.2;
    float total_weight = 1.2;
    for (int index = 0; index < SIZE; ++index) {
        float age = float(index + 1) / float(max(SIZE, 1));
        float old_bass = history_fft(index, 0.03);
        float old_middle = history_fft(index, 0.22);
        float old_treble = history_fft(index, 0.66);
        float old_tunnel = tunnel + age * (0.13 + old_bass * 0.24);
        float old_angle = angle + old_tunnel * (1.5 + old_middle * 2.2);
        vec2 cache_point = vec2(cos(old_angle), sin(old_angle)) *
                           fract(old_tunnel) * (0.74 - age * 0.08);
        vec2 cache_uv = cache_point / vec2(aspect, 1.0) + center;
        vec3 memory = sample_cache(index, cache_uv);
        memory = mix(memory, memory.brg, old_treble * 0.48);
        memory *= 0.68 + palette(old_angle / TAU + age) * 0.55;
        float weight = exp(-age * 2.15) * (0.7 + old_bass * 0.55);
        accumulated += memory * weight;
        total_weight += weight;
    }

    vec3 result = accumulated / total_weight;
    result += palette(tunnel - time_f * 0.04) * edge * amp_peak * 0.22;
    result = (result - 0.5) * (1.12 + amp_smooth * 0.3) + 0.5;
    color = vec4(clamp(result, 0.0, 1.0), texture(samp, tc).a);
}
