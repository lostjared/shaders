#version 330 core
// Fluid radial symmetry melts old frames into an FFT-driven mandala.

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
    return 0.5 + 0.5 * cos(TAU * (phase + vec3(0.11, 0.42, 0.74)));
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

vec2 mandala_map(vec2 point, float bass, float middle, float treble,
                 float age) {
    float radius = length(point) + 0.0001;
    float angle = atan(point.y, point.x);
    float sides = 5.0 + floor(treble * 7.0);
    float sector = TAU / sides;
    angle = abs(mod(angle + sector * 0.5, sector) - sector * 0.5);
    angle += sin(radius * (15.0 + middle * 9.0) - time_f * 2.4 -
                 age * 7.0) * (0.12 + bass * 0.32);
    radius += sin(angle * sides * 2.0 + time_f + age * 8.0) *
              (0.015 + middle * 0.025);
    return vec2(cos(angle), sin(angle)) * radius;
}

void main() {
    vec2 resolution = max(iResolution, vec2(1.0));
    float aspect = resolution.x / resolution.y;
    vec2 center = iMouse.z > 0.0 ? iMouse.xy / resolution : vec2(0.5);
    vec2 point = (tc - center) * vec2(aspect, 1.0);
    float bass = max(texture(spectrum0, 0.025).r, amp_low);
    float middle = max(texture(spectrum0, 0.3).r, amp_mid);
    float treble = max(texture(spectrum0, 0.68).r, amp_high);
    vec2 mapped = mandala_map(point, bass, middle, treble, 0.0);
    vec2 live_uv = mapped / vec2(aspect, 1.0) + center;
    float phase = atan(mapped.y, mapped.x) / TAU + length(mapped) * 1.8;
    vec2 chroma = normalize(mapped + vec2(0.0001)) * (0.003 + treble * 0.018);
    vec3 live;
    live.r = texture(samp, mirror_repeat(live_uv + chroma)).r;
    live.g = texture(samp, mirror_repeat(live_uv)).g;
    live.b = texture(samp, mirror_repeat(live_uv - chroma)).b;
    live *= 0.72 + palette(phase + time_f * 0.025) * 0.65;

    vec3 accumulated = live * 1.25;
    float total_weight = 1.25;
    for (int index = 0; index < SIZE; ++index) {
        float age = float(index + 1) / float(max(SIZE, 1));
        float old_bass = history_fft(index, 0.025);
        float old_middle = history_fft(index, 0.3);
        float old_treble = history_fft(index, 0.68);
        vec2 cache_point = mandala_map(point, old_bass, old_middle,
                                       old_treble, age);
        cache_point *= 1.0 - age * (0.11 + old_bass * 0.08);
        vec2 cache_uv = cache_point / vec2(aspect, 1.0) + center;
        vec3 memory = sample_cache(index, cache_uv);
        memory *= 0.68 + palette(phase + age + old_middle) * 0.56;
        float weight = exp(-age * 2.2) * (0.68 + old_bass * 0.55);
        accumulated += memory * weight;
        total_weight += weight;
    }

    vec3 result = accumulated / total_weight;
    result = mix(result, 1.0 - result, smoothstep(0.9, 1.0, amp_peak) * 0.5);
    result = (result - 0.5) * (1.1 + amp_smooth * 0.3) + 0.5;
    color = vec4(clamp(result, 0.0, 1.0), texture(samp, tc).a);
}
