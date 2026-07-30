#version 330 core
// Kaleidoscopic polar vortex carrying each cache layer on a different spoke.
#define EFFECT_ID 28

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

const float PI = 3.14159265359;
const float TAU = 6.28318530718;

vec2 mirror_repeat(vec2 point) {
    return 1.0 - abs(mod(point, 2.0) - 1.0);
}

vec3 palette(float phase) {
    return 0.5 + 0.5 * cos(TAU * (phase + vec3(0.04, 0.38, 0.72)));
}

vec4 sample_cache(int index, vec2 uv) {
    return texture(history, vec3(mirror_repeat(uv), float(CACHE_HISTORY_LAYER(index))));
}

float sample_history(int index, float frequency) {
    int max_age = max(min(SIZE, spectrum_history_size) - 1, 0);
    int age = min(index + 1, max_age);
    return texture(spectrum_history, vec2(frequency, float(SPECTRUM_HISTORY_LAYER(age)))).r;
}

vec2 kaleido_vortex(vec2 uv, vec2 center, float depth, float bass, float treble) {
    vec2 point = uv - center;
    float radius = length(point);
    float sectors = 5.0 + floor(treble * 5.0);
    float sector = TAU / sectors;
    float angle = atan(point.y, point.x) + radius * (4.0 + bass * 8.0) - time_f * 0.3;
    angle = abs(mod(angle + sector * 0.5, sector) - sector * 0.5);
    angle += depth * PI * (0.25 + treble);
    radius /= 1.0 + depth * (0.45 + bass);
    return vec2(cos(angle), sin(angle)) * radius + center;
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
        float treble = sample_history(index, 0.66);
        vec2 uv = kaleido_vortex(tc, center, depth, bass, treble);
        float spoke = 0.65 + 0.35 * cos(atan(uv.y - center.y, uv.x - center.x) * 10.0);
        float weight = mix(0.1, 0.6, depth) * spoke;
        accumulated += sample_cache(index, uv).rgb * palette(depth * 0.8 + treble) * weight;
        total_weight += weight;
    }

    vec3 result = accumulated / total_weight;
    result += palette(time_f * 0.05) * amp_peak * 0.1;
    result = (result - 0.5) * (1.1 + amp_smooth * 0.28) + 0.5;
    color = vec4(clamp(result, 0.0, 1.0), live.a);
}
