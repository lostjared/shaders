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

// Slow aurora curtains drift across softly stretched temporal layers.
#define EFFECT_ID 47
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
    return 0.5 + 0.5 * cos(TAU * (phase + vec3(0.19, 0.46, 0.68)));
}

vec4 sample_cache(int index, vec2 uv) {
    return texture(history, vec3(mirror_repeat(uv), float(CACHE_HISTORY_LAYER(index))));
}

float sample_history(int index, float frequency) {
    int max_age = max(min(SIZE, spectrum_history_size) - 1, 0);
    int age = min(index + 1, max_age);
    return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(age)))).r;
}

vec2 aurora_warp(vec2 uv, float depth, float bass, float middle) {
    float curtain = sin(uv.y * 8.0 + time_f * 0.7 + depth * 4.0);
    curtain += 0.5 * sin(uv.y * 17.0 - time_f * 0.43 + depth * TAU);
    uv.x += curtain * depth * (0.012 + middle * 0.045);
    uv.y += sin(uv.x * 6.0 - time_f * 0.3) * bass * depth * 0.02;
    uv = (uv - 0.5) / vec2(1.0 + depth * 0.15, 1.0 + depth * (0.28 + bass * 0.5)) + 0.5;
    return uv;
}

void main() {
    vec4 live = texture(samp, tc);
    vec3 accumulated = live.rgb;
    float total_weight = 1.0;

    for (int index = 0; index < SIZE; ++index) {
        float depth = float(index) / float(max(SIZE - 1, 1));
        float bass = sample_history(index, 0.035);
        float middle = sample_history(index, 0.22);
        vec2 uv = aurora_warp(tc, depth, bass, middle);
        float curtain = pow(abs(sin(uv.x * 10.0 + sin(uv.y * 8.0) + time_f * 0.4)), 3.0);
        float weight = mix(0.08, 0.52, depth) * (0.6 + curtain * 0.55);
        accumulated += sample_cache(index, uv).rgb * palette(depth * 0.6 + middle + tc.y * 0.25) * weight;
        total_weight += weight;
    }

    vec3 result = accumulated / total_weight;
    result += palette(tc.y * 0.4 + time_f * 0.03) * amp_peak * 0.08;
    result = (result - 0.5) * (1.06 + amp_smooth * 0.23) + 0.5;
    color = vec4(clamp(result, 0.0, 1.0), live.a);
}
