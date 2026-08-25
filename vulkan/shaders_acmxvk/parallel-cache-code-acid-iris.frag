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
#define amp_peak ext.u2.w
#define amp_smooth ext.u3.w
#define history_head int(ext.u3.x)
#define iMouse ext.mouse
#define iResolution ext.u0.zw
#define spectrum_history_head int(ext.audio_history.x)
#define spectrum_history_size int(ext.audio_history.y)
#define time_f ext.u2.y

// Breathing spectral iris whose petals expose nested cached frames.
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
    float c = cos(angle);
    float s = sin(angle);
    return mat2(c, -s, s, c);
}

vec2 mirror_repeat(vec2 point) {
    return 1.0 - abs(mod(point, 2.0) - 1.0);
}

vec3 palette(float phase) {
    return 0.5 + 0.5 * cos(TAU * (phase + vec3(0.03, 0.39, 0.7)));
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

    float petals = 7.0 + floor(treble * 6.0);
    float aperture = 0.23 + bass * 0.16 + sin(time_f * 1.3) * 0.025;
    float petal_radius = aperture + cos(angle * petals + time_f * (0.8 + mid)) *
                         (0.07 + mid * 0.055);
    float iris_edge = smoothstep(0.035, 0.0, abs(radius - petal_radius));
    float radial_fold = abs(mod(radius * 4.0 + time_f * 0.28, 1.0) - 0.5) * 2.0;
    // Doubling the petal coordinate closes it over mirror_repeat's two-unit period.
    vec2 iris_uv = vec2(angle / TAU * petals * 2.0 + radial_fold * 0.18,
                        radial_fold + sin(angle * petals) * 0.09);
    vec3 live = texture(samp, mirror_repeat(iris_uv)).rgb;
    vec3 accum = live;
    float total_weight = 1.0;

    for (int i = 0; i < 8; ++i) {
        float age = float(i + 1);
        float old_bass = sample_history(i, 0.03);
        float old_mid = sample_history(i, 0.22);
        float old_high = sample_history(i, 0.58);
        vec2 old_point = rotate_2d(age * (0.03 + old_high * 0.1)) * point;
        float old_radius = length(old_point) * (1.0 + age * (0.018 + old_bass * 0.035));
        float old_angle = atan(old_point.y, old_point.x);
        float fold = abs(mod(old_radius * 4.0 + age * old_mid * 0.2, 1.0) - 0.5) * 2.0;
        vec2 history_uv = vec2(old_angle / TAU * petals * 2.0 + fold * 0.18,
                               fold + sin(old_angle * petals + age) * old_high * 0.1);
        vec3 cached = sample_cache(i, history_uv).rgb;
        float weight = pow(0.78, age);
        accum += mix(cached, cached.gbr, old_mid * 0.4) *
                 palette(fold + age * 0.07 + old_high) * weight;
        total_weight += weight;
    }

    vec3 result = accum / total_weight;
    float pupil = 1.0 - smoothstep(0.03 + bass * 0.02, 0.11 + bass * 0.04, radius);
    result *= 0.68 + palette(radial_fold + time_f * 0.05) * (0.55 + mid * 0.45);
    result += palette(angle / TAU + time_f * 0.1) * iris_edge * (0.5 + air * 1.5);
    result *= 1.0 - pupil * (0.65 - bass * 0.25);
    result = (result - 0.5) * (1.16 + amp_smooth * 0.3) + 0.5;
    result = mix(result, vec3(1.0) - result, smoothstep(0.88, 1.0, amp_peak));
    color = vec4(clamp(result, 0.0, 1.0), texture(samp, tc).a);
}
