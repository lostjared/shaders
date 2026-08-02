#version 330 core
// Audio-folded petals grow through the texture cache.

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
    return 0.5 + 0.5 * cos(TAU * (phase + vec3(0.02, 0.31, 0.67)));
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

void main() {
    vec2 resolution = max(iResolution, vec2(1.0));
    float aspect = resolution.x / resolution.y;
    vec2 center = iMouse.z > 0.0 ? iMouse.xy / resolution : vec2(0.5);
    vec2 point = (tc - center) * vec2(aspect, 1.0);
    float bass = max(texture(spectrum0, 0.035).r, amp_low);
    float middle = max(texture(spectrum0, 0.28).r, amp_mid);
    float treble = max(texture(spectrum0, 0.72).r, amp_high);
    float radius = length(point) + 0.0001;
    float angle = atan(point.y, point.x);
    float petals = 6.0 + floor(treble * 8.0);
    float sector = TAU / petals;
    float folded = abs(mod(angle + sector * 0.5, sector) - sector * 0.5);
    vec2 bloom_point = vec2(cos(folded), sin(folded)) * radius;
    bloom_point = rotate_2d(sin(radius * 12.0 - time_f * 2.0) *
                            (0.15 + middle * 0.35)) * bloom_point;
    vec2 live_uv = bloom_point / vec2(aspect, 1.0) + center;
    vec3 live = texture(samp, mirror_repeat(live_uv)).rgb;
    float petal_light = pow(abs(cos(folded * petals * 0.5)), 8.0);
    live += palette(radius * 1.7 - time_f * 0.06) * petal_light *
            (0.12 + treble * 0.3);

    vec3 accumulated = live * 1.2;
    float total_weight = 1.2;
    for (int index = 0; index < SIZE; ++index) {
        float age = float(index + 1) / float(max(SIZE, 1));
        float old_bass = history_fft(index, 0.035);
        float old_treble = history_fft(index, 0.72);
        vec2 cache_point = bloom_point;
        cache_point = rotate_2d(age * (0.22 + old_treble * 0.9)) * cache_point;
        cache_point *= 1.0 - age * (0.13 + old_bass * 0.11);
        cache_point += normalize(cache_point + vec2(0.0001)) *
                       sin(radius * 30.0 - age * 12.0) * old_bass * 0.018;
        vec2 cache_uv = cache_point / vec2(aspect, 1.0) + center;
        vec3 memory = sample_cache(index, cache_uv);
        memory *= 0.62 + palette(age + old_treble) * 0.64;
        float weight = exp(-age * 2.1) * (0.72 + old_bass * 0.5);
        accumulated += memory * weight;
        total_weight += weight;
    }

    vec3 result = accumulated / total_weight;
    result = (result - 0.5) * (1.1 + amp_smooth * 0.35) + 0.5;
    result = mix(result, result.brg, smoothstep(0.86, 1.0, amp_peak) * 0.7);
    color = vec4(clamp(result, 0.0, 1.0), texture(samp, tc).a);
}
