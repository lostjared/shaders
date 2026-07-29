#version 330 core
// ant_time_f_color_acid_smear
// Aggressive acidic feedback smear: each cache frame distorted via its FFT slot's wave
// Cache (samp1..samp8) + FFT history (spectrum0..7) made visually obvious.

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
uniform float amp_peak;
uniform float amp_smooth;

const float TAU = 6.28318530718;
const float PI  = 3.14159265359;

vec3 acid(float t) {
    return 0.5 + 0.5 * cos(TAU * (vec3(1.0, 1.0, 0.5) * t + vec3(0.3, 0.2, 0.2)));
}

vec3 palette(float t, vec3 d) {
    return 0.5 + 0.5 * cos(TAU * (vec3(1.0) * t + d));
}

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// 0 -> live samp, 1..8 -> samp1..samp8 (oldest)
vec4 cacheHist(int i, vec2 uv) {
    if (i == 0) return texture(samp,  uv);
    if (i == 1) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(0))));
    if (i == 2) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(1))));
    if (i == 3) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(2))));
    if (i == 4) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(3))));
    if (i == 5) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(4))));
    if (i == 6) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(5))));
    if (i == 7) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(6))));
    return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(7))));
}

// 0 -> spectrum0 (now), 7 -> spectrum7 (oldest)
float specHist(int i, float f) {
    if (i == 0) return texture(spectrum0, f).r;
    if (i == 1) return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(1)))).r;
    if (i == 2) return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(2)))).r;
    if (i == 3) return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(3)))).r;
    if (i == 4) return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(4)))).r;
    if (i == 5) return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(5)))).r;
    if (i == 6) return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(6)))).r;
    return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(7)))).r;
}

float histEnergy(float f) {
    float e = 0.0;
    for (int i = 0; i < 8; i++) e += specHist(i, f);
    return e;
}

void main() {
    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);
    float bass   = texture(spectrum0, 0.03).r;
    float mid    = texture(spectrum0, 0.22).r;
    float treble = texture(spectrum0, 0.58).r;
    float air    = texture(spectrum0, 0.85).r;
    float E_bass   = histEnergy(0.03);
    float E_mid    = histEnergy(0.22);
    float E_treble = histEnergy(0.58);
    float E_air    = histEnergy(0.85);

    vec3 acc = vec3(0.0); float wsum = 0.0;
    for (int i = 0; i < 9; i++) {
        float h = specHist(min(i, 7), 0.1 + float(i) * 0.06) * 5.0;
        float h2 = specHist(min(i, 7), 0.6) * 5.0;
        vec2 d = vec2(sin(uv.y * (4.0 + h * 8.0) + time_f * 0.5 + float(i)),
                      cos(uv.x * (4.0 + h2 * 8.0) - time_f * 0.4 + float(i)))
                 * 0.05 * (1.0 + h);
        vec3 c = cacheHist(i, tc + d).rgb;
        vec3 tint = acid(float(i) * 0.13 + h * 0.4 + time_f * 0.05);
        float w = pow(0.82, float(i)) * (1.0 + h);
        acc += c * tint * w;
        wsum += w;
    }
    acc /= wsum;
    acc *= 1.4 + amp_peak * 1.2;
    color = vec4(clamp(acc, 0.0, 1.0), 1.0);
}
