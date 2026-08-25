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

// Rotating 4D tesseract projection used to orbit temporal layers.
#define EFFECT_ID 26
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
    return 0.5 + 0.5 * cos(TAU * (phase + vec3(0.12, 0.45, 0.78)));
}

vec4 sample_cache(int index, vec2 uv) {
    return texture(history, vec3(mirror_repeat(uv), float(CACHE_HISTORY_LAYER(index))));
}

float sample_history(int index, float frequency) {
    int max_age = max(min(SIZE, spectrum_history_size) - 1, 0);
    int age = min(index + 1, max_age);
    return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(age)))).r;
}

vec2 project_tesseract(vec2 uv, vec2 center, float depth, float bass, float high) {
    vec2 point = uv - center;
    float z = sin(point.x * 4.0 + depth * TAU + time_f) * 0.45;
    float w = cos(point.y * 4.0 - depth * TAU + time_f * 0.73) * 0.45;
    float angle_xw = time_f * 0.32 + depth * 1.8 + high;
    float angle_yw = -time_f * 0.27 + depth * 1.3 + bass;
    float x = point.x * cos(angle_xw) - w * sin(angle_xw);
    w = point.x * sin(angle_xw) + w * cos(angle_xw);
    float y = point.y * cos(angle_yw) - w * sin(angle_yw);
    float perspective = 1.0 / max(0.55, 1.65 - z - w * 0.35);
    return vec2(x, y) * perspective * (1.0 + bass * 0.4) + center;
}

void main() {
    vec2 resolution = max(iResolution, vec2(1.0));
    vec2 center = iMouse.z > 0.0 ? iMouse.xy / resolution : vec2(0.5);
    vec4 live = texture(samp, tc);
    vec3 accumulated = live.rgb;
    float total_weight = 1.0;

    for (int index = 0; index < SIZE; ++index) {
        float depth = float(index) / float(max(SIZE - 1, 1));
        float bass = sample_history(index, 0.035);
        float high = sample_history(index, 0.64);
        vec2 uv = project_tesseract(tc, center, depth, bass, high);
        float cell = abs(sin((uv.x + uv.y) * 28.0 + depth * TAU));
        float edge = smoothstep(0.72, 1.0, cell);
        float weight = mix(0.12, 0.58, depth) * mix(0.65, 1.25, edge);
        accumulated += sample_cache(index, uv).rgb * palette(depth + high + time_f * 0.04) * weight;
        total_weight += weight;
    }

    vec3 result = accumulated / total_weight;
    result += palette(time_f * 0.09) * amp_peak * 0.12;
    result = (result - 0.5) * (1.08 + amp_smooth * 0.24) + 0.5;
    color = vec4(clamp(result, 0.0, 1.0), live.a);
}
