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

// Three interwoven plasma strands braid cached frames through time.
#define EFFECT_ID 40
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
    return 0.5 + 0.5 * cos(TAU * (phase + vec3(0.11, 0.44, 0.80)));
}

vec4 sample_cache(int index, vec2 uv) {
    return texture(history, vec3(mirror_repeat(uv), float(CACHE_HISTORY_LAYER(index))));
}

float sample_history(int index, float frequency) {
    int max_age = max(min(SIZE, spectrum_history_size) - 1, 0);
    int age = min(index + 1, max_age);
    return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(age)))).r;
}

vec2 braid_warp(vec2 uv, float depth, float bass, float middle) {
    float phase = uv.y * (12.0 + middle * 8.0) - time_f * 2.0 + depth * TAU;
    float strand_a = sin(phase);
    float strand_b = sin(phase + TAU / 3.0);
    float strand_c = sin(phase + 2.0 * TAU / 3.0);
    float braid = mix(strand_a, strand_b, smoothstep(-0.4, 0.4, strand_c));
    uv.x += braid * depth * (0.018 + bass * 0.065);
    uv.y += cos(uv.x * 15.0 + phase) * middle * depth * 0.015;
    return (uv - 0.5) / (1.0 + depth * (0.2 + bass * 0.7)) + 0.5;
}

void main() {
    vec4 live = texture(samp, tc);
    vec3 accumulated = live.rgb;
    float total_weight = 1.0;

    for (int index = 0; index < SIZE; ++index) {
        float depth = float(index) / float(max(SIZE - 1, 1));
        float bass = sample_history(index, 0.03);
        float middle = sample_history(index, 0.26);
        vec2 uv = braid_warp(tc, depth, bass, middle);
        float strand = pow(abs(sin(uv.y * 20.0 - time_f * 2.0 + depth * TAU)), 5.0);
        float weight = mix(0.08, 0.58, depth) * (0.62 + strand * 0.58);
        accumulated += sample_cache(index, uv).rgb * palette(depth + middle + time_f * 0.06) * weight;
        total_weight += weight;
    }

    vec3 result = accumulated / total_weight;
    result += result.gbr * amp_peak * 0.1;
    result = (result - 0.5) * (1.1 + amp_smooth * 0.26) + 0.5;
    color = vec4(clamp(result, 0.0, 1.0), live.a);
}
