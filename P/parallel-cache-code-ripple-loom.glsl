#version 330 core
// Three-source interference woven through mirrored polar cache ribbons.

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform sampler2DArray history;
uniform int history_head;
#ifndef SIZE
#define SIZE 8
#endif
#ifndef CACHE_HISTORY_LAYER
#define CACHE_HISTORY_LAYER(index) ((history_head + (index)) % SIZE)
#endif

uniform sampler1D spectrum0;
uniform sampler1DArray spectrum_history;
uniform int spectrum_history_head;
uniform int spectrum_history_size;
#ifndef SPECTRUM_HISTORY_LAYER
#define SPECTRUM_HISTORY_LAYER(index) ((spectrum_history_head - ((index) % max(spectrum_history_size, 1)) + max(spectrum_history_size, 1)) % max(spectrum_history_size, 1))
#endif

uniform float time_f;
uniform vec2 iResolution;
uniform vec4 iMouse;
uniform float amp_peak;
uniform float amp_smooth;

const float TAU = 6.28318530718;

vec2 mirror_repeat(vec2 point) {
    return 1.0 - abs(mod(point, 2.0) - 1.0);
}

vec3 acid_palette(float phase) {
    return 0.5 + 0.5 * cos(TAU * (phase + vec3(0.31, 0.08, 0.73)));
}

vec4 sample_cache(int index, vec2 uv) {
    uv = mirror_repeat(uv);
    if (index == 0) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(0))));
    if (index == 1) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(1))));
    if (index == 2) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(2))));
    if (index == 3) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(3))));
    if (index == 4) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(4))));
    if (index == 5) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(5))));
    if (index == 6) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(6))));
    return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(7))));
}

float sample_history(int index, float frequency) {
    if (index == 0) return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(1)))).r;
    if (index == 1) return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(2)))).r;
    if (index == 2) return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(3)))).r;
    if (index == 3) return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(4)))).r;
    if (index == 4) return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(5)))).r;
    if (index == 5) return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(6)))).r;
    return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(7)))).r;
}

void main() {
    vec2 resolution = max(iResolution, vec2(1.0));
    float aspect = resolution.x / resolution.y;
    vec2 center = iMouse.z > 0.5 ? iMouse.xy / resolution : vec2(0.5);
    vec2 point = (tc - center) * vec2(aspect, 1.0);

    float bass = texture(spectrum0, 0.03).r;
    float mid = texture(spectrum0, 0.22).r;
    float treble = texture(spectrum0, 0.58).r;
    float air = texture(spectrum0, 0.80).r;

    vec2 source_a = vec2(sin(time_f * 0.31), cos(time_f * 0.43)) * 0.19;
    vec2 source_b = vec2(-sin(time_f * 0.53), sin(time_f * 0.29)) * 0.16;
    vec2 source_c = vec2(cos(time_f * 0.23), -cos(time_f * 0.61)) * 0.12;
    float wave_a = sin(length(point - source_a) * (21.0 + bass * 17.0) - time_f * 5.0);
    float wave_b = sin(length(point - source_b) * (18.0 + mid * 14.0) - time_f * 4.1);
    float wave_c = sin(length(point - source_c) * (24.0 + treble * 12.0) - time_f * 6.2);
    float interference = (wave_a + wave_b + wave_c) / 3.0;

    float radius = length(point) + 0.001;
    float angle = atan(point.y, point.x);
    float shuttle = abs(mod(radius * 2.0 + time_f * 0.35, 1.0) - 0.5) * 2.0;
    // mirror_repeat has a period of two, so a full turn must span an even count.
    float angular_repeat = 2.0 * (5.0 + floor(treble * 4.0));
    vec2 loom_uv = vec2(angle / TAU * angular_repeat,
                        shuttle + interference * (0.13 + bass * 0.08));
    loom_uv += vec2(wave_a - wave_b, wave_b - wave_c) * 0.035;

    float chroma = abs(interference) * 0.045 + treble * 0.035;
    vec3 live;
    live.r = texture(samp, mirror_repeat(loom_uv + vec2(chroma, 0.0))).r;
    live.g = texture(samp, mirror_repeat(loom_uv)).g;
    live.b = texture(samp, mirror_repeat(loom_uv - vec2(chroma, 0.0))).b;

    vec3 accum = live * (1.0 + amp_smooth * 0.25);
    float total_weight = 1.0;
    vec2 tangent = vec2(-point.y, point.x) / radius;

    for (int i = 0; i < 8; ++i) {
        float age = float(i + 1);
        float old_bass = sample_history(i, 0.03);
        float old_mid = sample_history(i, 0.22);
        float old_air = sample_history(i, 0.80);
        vec2 history_uv = loom_uv;
        history_uv += tangent * age * (0.018 + old_mid * 0.055);
        history_uv.y += age * (0.025 + old_bass * 0.08);
        history_uv.x += sin(history_uv.y * TAU + age + time_f) * old_air * 0.07;
        vec3 cached = sample_cache(i, history_uv).rgb;
        float thread = pow(abs(sin((history_uv.x + history_uv.y) * TAU)), 5.0);
        float weight = pow(0.79, age);
        accum += mix(cached, cached.gbr, old_mid * 0.42) * weight * (0.65 + thread * 0.7);
        total_weight += weight;
    }

    vec3 result = accum / total_weight;
    float crest = pow(max(interference, 0.0), 7.0);
    result *= acid_palette(interference * 0.2 + time_f * 0.08 + bass) * 1.35;
    result += acid_palette(radius + time_f * 0.13) * crest * (0.6 + air * 2.0);
    result = mix(result, vec3(1.0) - result, smoothstep(0.9, 1.0, amp_peak));
    color = vec4(clamp(result, 0.0, 1.0), texture(samp, tc).a);
}
