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

// Audio-driven threaded drill with eight layers of rotating temporal feedback.
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

vec3 acid_palette(float phase) {
    return 0.52 + 0.48 * cos(TAU * (phase + vec3(0.02, 0.35, 0.68)));
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
    float air = texture(spectrum0, 0.80).r;

    float depth = 1.0 / (radius + 0.055 + bass * 0.025) + time_f * (1.5 + bass * 2.0);
    float thread_a = sin(angle * (8.0 + floor(treble * 6.0)) - depth * (3.0 + mid));
    float thread_b = cos(angle * 17.0 + depth * (4.7 + treble * 2.0));
    float drill_angle = angle + depth * (0.62 + bass * 0.2) + thread_a * 0.17;
    vec2 drill_uv = mirror_repeat(vec2(drill_angle / TAU * 4.0 + thread_b * 0.07,
                                        depth * 0.31 + log(radius) * 0.75 + thread_a * 0.12));

    vec3 live = texture(samp, drill_uv).rgb;
    vec3 accum = live;
    float total_weight = 1.0;

    for (int i = 0; i < 8; ++i) {
        float age = float(i + 1);
        float old_bass = sample_history(i, 0.03);
        float old_mid = sample_history(i, 0.22);
        float old_high = sample_history(i, 0.58);
        vec2 feedback_point = rotate_2d(age * (0.025 + old_high * 0.11)) * point;
        feedback_point *= pow(max(0.975 - old_bass * 0.055, 0.72), age);
        float old_radius = length(feedback_point) + 0.002;
        float old_angle = atan(feedback_point.y, feedback_point.x);
        float old_depth = depth + age * (0.42 + old_mid * 1.3);
        vec2 feedback_uv = vec2(old_angle / TAU * 4.0 + old_depth * 0.095,
                                old_depth * 0.31 + log(old_radius) * 0.75);
        feedback_uv += vec2(thread_b, thread_a) * old_high * 0.08;
        vec3 cached = sample_cache(i, feedback_uv).rgb;
        cached *= acid_palette(old_depth * 0.025 + age * 0.09 + old_mid);
        float weight = pow(0.76, age) * (0.75 + old_bass * 0.5);
        accum += cached * weight;
        total_weight += weight;
    }

    vec3 result = accum / total_weight;
    float metal = pow(0.5 + 0.5 * thread_a, 3.0);
    result = mix(result, result.bgr, 0.18 + metal * 0.28);
    result *= 0.64 + metal * (0.8 + mid) + abs(thread_b) * 0.18;
    result += acid_palette(angle / TAU + time_f * 0.08) * pow(max(thread_b, 0.0), 8.0) * air;
    result = mix(result, vec3(1.0) - result, smoothstep(0.88, 1.0, amp_peak));
    color = vec4(clamp(result, 0.0, 1.0), texture(samp, tc).a);
}
