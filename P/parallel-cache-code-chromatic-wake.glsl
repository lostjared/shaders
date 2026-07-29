#version 330 core
// Motion-only rainbow wakes wrapped around an audio-reactive spiral.

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

mat2 rotate_2d(float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return mat2(c, -s, s, c);
}

vec2 mirror_repeat(vec2 point) {
    return 1.0 - abs(mod(point, 2.0) - 1.0);
}

vec3 palette(float phase) {
    return 0.5 + 0.5 * cos(TAU * (phase + vec3(0.0, 0.34, 0.67)));
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
    float radius = length(point) + 0.002;
    float angle = atan(point.y, point.x);
    float bass = texture(spectrum0, 0.03).r;
    float mid = texture(spectrum0, 0.22).r;
    float treble = texture(spectrum0, 0.58).r;
    float air = texture(spectrum0, 0.82).r;

    float spiral = sin(angle * (5.0 + floor(treble * 5.0)) -
                       radius * (18.0 - bass * 7.0) - time_f * (3.0 + mid * 3.0));
    vec2 normal = vec2(cos(angle), sin(angle));
    vec2 live_uv = mirror_repeat(tc + normal * spiral * (0.018 + mid * 0.04));
    vec3 live = texture(samp, live_uv).rgb;
    vec3 trail = vec3(0.0);
    float trail_weight = 0.0;

    for (int i = 0; i < 8; ++i) {
        float age = float(i + 1);
        float old_bass = sample_history(i, 0.03);
        float old_mid = sample_history(i, 0.22);
        float old_high = sample_history(i, 0.58);
        vec2 old_point = rotate_2d(age * (0.025 + old_high * 0.12)) * point;
        old_point *= pow(max(0.98 - old_bass * 0.055, 0.6), age);
        vec2 history_uv = old_point / vec2(aspect, 1.0) + center;
        history_uv += vec2(-old_point.y, old_point.x) * old_mid * 0.08;
        history_uv = mirror_repeat(history_uv);
        vec3 cached = sample_cache(i, history_uv).rgb;
        vec3 current = texture(samp, history_uv).rgb;
        float motion = smoothstep(0.025, 0.18, dot(abs(cached - current), vec3(0.333)));
        float weight = pow(0.81, age);
        trail += palette(age * 0.12 + old_high + time_f * 0.04) * motion * weight;
        trail_weight += motion * weight;
    }

    float wake = clamp(trail_weight * 0.35, 0.0, 1.0);
    vec3 result = 1.0 - (1.0 - live) * (1.0 - clamp(trail, 0.0, 1.0) * wake);
    float crest = pow(max(spiral, 0.0), 7.0);
    result += palette(angle / TAU + time_f * 0.08) * crest * (0.15 + air);
    result = (result - 0.5) * (1.12 + amp_smooth * 0.35) + 0.5;
    result = mix(result, vec3(1.0) - result, smoothstep(0.9, 1.0, amp_peak));
    color = vec4(clamp(result, 0.0, 1.0), texture(samp, tc).a);
}
