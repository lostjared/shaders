#version 330 core
// An audio-twisted Mobius ribbon drags luminous cache echoes around itself.

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
uniform float amp_low;
uniform float amp_mid;
uniform float amp_high;

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
    return 0.5 + 0.5 * cos(TAU * (phase + vec3(0.13, 0.46, 0.8)));
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

float ribbon_field(vec2 point, float bass, float middle, float treble,
                   float age) {
    float radius = length(point) + 0.0001;
    float angle = atan(point.y, point.x);
    float orbit_phase = time_f * 0.8 + age * 4.0;
    float orbit_wave = sin(angle + orbit_phase);
    float cross_twist = sin(angle * 2.0 - orbit_phase * 0.7);
    float center_line = 0.34 + orbit_wave * (0.075 + middle * 0.045) +
                        cross_twist * (0.025 + middle * 0.015);
    float twist = sin(angle * 3.0 - time_f * 1.6 - age * 9.0) *
                  (0.055 + treble * 0.045);
    return radius - center_line - twist - bass * 0.025;
}

void main() {
    vec2 resolution = max(iResolution, vec2(1.0));
    float aspect = resolution.x / resolution.y;
    vec2 center = iMouse.z > 0.0 ? iMouse.xy / resolution : vec2(0.5);
    vec2 point = (tc - center) * vec2(aspect, 1.0);
    float bass = max(texture(spectrum0, 0.04).r, amp_low);
    float middle = max(texture(spectrum0, 0.36).r, amp_mid);
    float treble = max(texture(spectrum0, 0.79).r, amp_high);
    float field = ribbon_field(point, bass, middle, treble, 0.0);
    float angle = atan(point.y, point.x);
    vec2 normal = normalize(point + vec2(0.0001));
    vec2 tangent = vec2(-normal.y, normal.x);
    vec2 live_uv = tc - normal * field * (0.16 + bass * 0.12) +
                   tangent * sin(angle * 3.0 - time_f) * treble * 0.018;
    vec3 live = texture(samp, mirror_repeat(live_uv)).rgb;
    float ribbon = exp(-abs(field) * (38.0 + treble * 25.0));
    live += palette(angle / TAU + time_f * 0.04) * ribbon *
            (0.2 + treble * 0.42);

    vec3 accumulated = live * 1.2;
    float total_weight = 1.2;
    for (int index = 0; index < SIZE; ++index) {
        float age = float(index + 1) / float(max(SIZE, 1));
        float old_bass = history_fft(index, 0.04);
        float old_middle = history_fft(index, 0.36);
        float old_treble = history_fft(index, 0.79);
        float old_field = ribbon_field(point, old_bass, old_middle,
                                       old_treble, age);
        vec2 cache_point = rotate_2d(age * (0.25 + old_middle * 0.7)) * point;
        cache_point -= normalize(cache_point + vec2(0.0001)) * old_field *
                       (0.11 + old_bass * 0.1);
        cache_point *= 1.0 - age * 0.075;
        vec2 cache_uv = cache_point / vec2(aspect, 1.0) + center;
        vec3 memory = sample_cache(index, cache_uv);
        memory *= 0.66 + palette(angle / TAU + age + old_treble) * 0.6;
        float old_ribbon = exp(-abs(old_field) * 30.0);
        memory += palette(age - time_f * 0.025) * old_ribbon * 0.1;
        float weight = exp(-age * 2.4) * (0.68 + old_middle * 0.5);
        accumulated += memory * weight;
        total_weight += weight;
    }

    vec3 result = accumulated / total_weight;
    result = mix(result, result.gbr, smoothstep(0.87, 1.0, amp_peak) * 0.6);
    result = (result - 0.5) * (1.1 + amp_smooth * 0.32) + 0.5;
    color = vec4(clamp(result, 0.0, 1.0), texture(samp, tc).a);
}
