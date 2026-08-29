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

// Strobing scanline shutters slice and reorder the temporal trail.
#define EFFECT_ID 39
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

float hash_1d(float value) {
    return fract(sin(value * 91.3458) * 47453.5453);
}

vec3 palette(float phase) {
    return 0.5 + 0.5 * cos(TAU * (phase + vec3(0.02, 0.37, 0.71)));
}

vec4 sample_cache(int index, vec2 uv) {
    return texture(history, vec3(mirror_repeat(uv), float(CACHE_HISTORY_LAYER(index))));
}

float sample_history(int index, float frequency) {
    int max_age = max(min(SIZE, spectrum_history_size) - 1, 0);
    int age = min(index + 1, max_age);
    return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(age)))).r;
}

vec2 glitch_warp(vec2 uv, float depth, float bass, float high) {
    float row = floor(uv.y * (18.0 + high * 24.0));
    float tick = floor(time_f * (6.0 + bass * 10.0));
    float random_value = hash_1d(row + tick * 37.0 + depth * 11.0);
    float gate = step(0.7 - high * 0.2, random_value);
    uv.x += (random_value - 0.5) * gate * depth * (0.08 + bass * 0.2);
    uv.y += (hash_1d(row * 3.1 + tick) - 0.5) * gate * 0.025;
    return (uv - 0.5) / (1.0 + depth * 0.14) + 0.5;
}

void main() {
    vec4 live = texture(samp, tc);
    vec3 accumulated = live.rgb;
    float total_weight = 1.0;

    for (int index = 0; index < SIZE; ++index) {
        float depth = float(index) / float(max(SIZE - 1, 1));
        float bass = sample_history(index, 0.03);
        float high = sample_history(index, 0.68);
        vec2 uv = glitch_warp(tc, depth, bass, high);
        float shutter = step(0.35, fract(time_f * 7.0 + depth * 2.3 + floor(tc.y * 20.0) * 0.17));
        float weight = mix(0.06, 0.52, depth) * mix(0.22, 1.15, shutter);
        vec3 cached = sample_cache(index, uv).rgb;
        cached = mix(cached, cached.brg, step(0.75, hash_1d(float(index) + floor(time_f * 5.0))));
        accumulated += cached * palette(depth + high) * weight;
        total_weight += weight;
    }

    vec3 result = accumulated / total_weight;
    result = mix(result, vec3(1.0) - result, smoothstep(0.9, 1.0, amp_peak) * 0.45);
    result = (result - 0.5) * (1.14 + amp_smooth * 0.24) + 0.5;
    color = vec4(clamp(result, 0.0, 1.0), live.a);
}
