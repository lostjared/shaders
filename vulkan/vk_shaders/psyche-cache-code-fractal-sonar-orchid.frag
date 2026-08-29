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

// Recursive orchid folds pulse outward as spectrum-shaped sonar.
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
    return 0.5 + 0.5 * cos(TAU * (phase + vec3(0.2, 0.5, 0.83)));
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

vec2 orchid_fold(vec2 point, float middle, float age) {
    for (int fold = 0; fold < 4; ++fold) {
        point = abs(point) - vec2(0.22, 0.31);
        point = rotate_2d(0.61 + middle * 0.3 + float(fold) * 0.17 +
                          age * 0.2) * point;
        point /= max(dot(point, point), 0.42);
        point *= 0.66;
    }
    return point;
}

void main() {
    vec2 resolution = max(iResolution, vec2(1.0));
    float aspect = resolution.x / resolution.y;
    vec2 center = iMouse.z > 0.0 ? iMouse.xy / resolution : vec2(0.5);
    vec2 point = (tc - center) * vec2(aspect, 1.0);
    float bass = max(texture(spectrum0, 0.04).r, amp_low);
    float middle = max(texture(spectrum0, 0.31).r, amp_mid);
    float treble = max(texture(spectrum0, 0.77).r, amp_high);
    vec2 orchid = orchid_fold(point, middle, 0.0);
    float radius = length(orchid) + 0.0001;
    float angle = atan(orchid.y, orchid.x);
    float sonar = sin(radius * (45.0 + bass * 28.0) - time_f * 8.0);
    float petals = pow(abs(cos(angle * (5.0 + floor(treble * 5.0)))), 7.0);
    vec2 live_uv = tc + normalize(orchid) * sonar * petals *
                   (0.015 + bass * 0.04);
    vec3 live = texture(samp, mirror_repeat(live_uv)).rgb;
    live += palette(angle / TAU + radius - time_f * 0.05) * petals *
            pow(max(sonar, 0.0), 7.0) * (0.16 + treble * 0.34);

    vec3 accumulated = live * 1.2;
    float total_weight = 1.2;
    for (int index = 0; index < SIZE; ++index) {
        float age = float(index + 1) / float(max(SIZE, 1));
        float old_bass = history_fft(index, 0.04);
        float old_middle = history_fft(index, 0.31);
        float old_treble = history_fft(index, 0.77);
        vec2 old_orchid = orchid_fold(point, old_middle, age);
        float old_radius = length(old_orchid) + 0.0001;
        float echo = sin(old_radius * (42.0 + old_bass * 26.0) - age * 19.0);
        vec2 cache_uv = tc + normalize(old_orchid) * echo *
                        (0.008 + old_bass * 0.025) * age;
        cache_uv = (rotate_2d(age * old_treble * 0.8) *
                   (cache_uv - center)) * (1.0 - age * 0.08) + center;
        vec3 memory = sample_cache(index, cache_uv);
        memory *= 0.65 + palette(old_radius + age) * 0.58;
        float weight = exp(-age * 2.25) * (0.68 + old_bass * 0.55);
        accumulated += memory * weight;
        total_weight += weight;
    }

    vec3 result = accumulated / total_weight;
    result += palette(angle / TAU + time_f * 0.04) * amp_peak * petals * 0.18;
    result = (result - 0.5) * (1.1 + amp_smooth * 0.32) + 0.5;
    color = vec4(clamp(result, 0.0, 1.0), texture(samp, tc).a);
}
