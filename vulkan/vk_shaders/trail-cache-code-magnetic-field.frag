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

// Dipole field-line curvature bends temporal layers around two poles.
#define EFFECT_ID 44
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
    return 0.5 + 0.5 * cos(TAU * (phase + vec3(0.15, 0.46, 0.76)));
}

vec4 sample_cache(int index, vec2 uv) {
    return texture(history, vec3(mirror_repeat(uv), float(CACHE_HISTORY_LAYER(index))));
}

float sample_history(int index, float frequency) {
    int max_age = max(min(SIZE, spectrum_history_size) - 1, 0);
    int age = min(index + 1, max_age);
    return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(age)))).r;
}

vec2 magnetic_warp(vec2 uv, vec2 center, float depth, float bass, float high) {
    vec2 point = uv - center;
    vec2 pole_a = vec2(-0.18 - bass * 0.05, 0.0);
    vec2 pole_b = vec2(0.18 + bass * 0.05, 0.0);
    vec2 delta_a = point - pole_a;
    vec2 delta_b = point - pole_b;
    vec2 field_a = vec2(-delta_a.y, delta_a.x) / (dot(delta_a, delta_a) + 0.035);
    vec2 field_b = vec2(delta_b.y, -delta_b.x) / (dot(delta_b, delta_b) + 0.035);
    point += (field_a + field_b) * depth * (0.0015 + high * 0.0045);
    point /= 1.0 + depth * (0.22 + bass * 0.55);
    return point + center;
}

void main() {
    vec2 resolution = max(iResolution, vec2(1.0));
    vec2 center = iMouse.z > 0.0 ? iMouse.xy / resolution : vec2(0.5);
    vec4 live = texture(samp, tc);
    vec3 accumulated = live.rgb;
    float total_weight = 1.0;

    for (int index = 0; index < SIZE; ++index) {
        float depth = float(index) / float(max(SIZE - 1, 1));
        float bass = sample_history(index, 0.025);
        float high = sample_history(index, 0.6);
        vec2 uv = magnetic_warp(tc, center, depth, bass, high);
        float lines = pow(abs(sin((length(tc - center + vec2(0.18, 0.0)) -
                                   length(tc - center - vec2(0.18, 0.0))) * 50.0)), 6.0);
        float weight = mix(0.08, 0.56, depth) * (0.65 + lines * 0.55);
        accumulated += sample_cache(index, uv).rgb * palette(depth + high) * weight;
        total_weight += weight;
    }

    vec3 result = accumulated / total_weight;
    result += palette(time_f * 0.08) * amp_peak * 0.1;
    result = (result - 0.5) * (1.1 + amp_smooth * 0.25) + 0.5;
    color = vec4(clamp(result, 0.0, 1.0), live.a);
}
