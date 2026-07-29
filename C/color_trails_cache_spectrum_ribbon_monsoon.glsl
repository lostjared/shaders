#version 330 core
// color_trails_cache_spectrum_ribbon_monsoon
// Rain-swept ribbon trails with heavy downward drag and broad spectral wash from the oldest frame.

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

vec3 acid(float t) {
    return 0.5 + 0.5 * cos(TAU * (vec3(0.55, 0.72, 1.0) * t + vec3(0.12, 0.24, 0.46)));
}

vec4 cacheHist(int i, vec2 uv) {
    if (i == 0) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(0))));
    if (i == 1) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(1))));
    if (i == 2) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(2))));
    if (i == 3) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(3))));
    if (i == 4) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(4))));
    if (i == 5) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(5))));
    if (i == 6) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(6))));
    return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(7))));
}

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

vec2 ribbonField(vec2 uv, float bass, float mid, float treble, float air, vec3 oldest, float layer) {
    float sweep = sin(uv.x * 9.0 + time_f * 1.0 + layer * 0.4 + bass * 8.0);
    float rain = cos(uv.y * 30.0 - time_f * 3.4 - layer * 0.6 + treble * 10.0);
    vec2 field = vec2(sweep * 0.4, -abs(rain) - 0.2);
    field += vec2(oldest.g - 0.5, oldest.b - oldest.r) * 0.7;
    return field * (0.013 + mid * 0.028 + air * 0.032);
}

void main() {
    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    float bass = texture(spectrum0, 0.03).r;
    float mid = texture(spectrum0, 0.21).r;
    float treble = texture(spectrum0, 0.58).r;
    float air = texture(spectrum0, 0.88).r;

    float histWet = 0.0;
    float histWind = 0.0;
    for (int i = 0; i < 8; i++) {
        histWet += specHist(i, 0.88);
        histWind += specHist(i, 0.21);
    }
    histWet /= 8.0;
    histWind /= 8.0;

    vec2 oldestWarp = vec2(
        sin(time_f * 0.28 + uv.y * 11.0 + histWind * 7.0),
        -abs(cos(time_f * 0.22 + uv.x * 5.0 - histWet * 9.0))
    ) * (0.014 + histWet * 0.038);
    vec3 oldest = texture(history, vec3(tc + oldestWarp, float(CACHE_HISTORY_LAYER(7)))).rgb;

    vec2 liveWarp = ribbonField(uv, bass, mid, treble, air, oldest, 0.0);
    vec3 live = texture(samp, tc + liveWarp).rgb;
    live *= acid(uv.y * 0.3 - time_f * 0.04 + histWet * 0.5);

    vec3 accum = live;
    float wsum = 1.0;
    for (int i = 0; i < 8; i++) {
        float layer = float(i + 1);
        float hBass = specHist(i, 0.03);
        float hMid = specHist(i, 0.21);
        float hTreble = specHist(i, 0.58);
        float hAir = specHist(i, 0.88);
        vec2 drift = ribbonField(uv, hBass, hMid, hTreble, hAir, oldest, layer);
        drift += vec2(sin(layer * 0.6), -layer * 0.003) * (1.0 + hAir * 6.0);
        vec3 cached = cacheHist(i, tc + drift).rgb;
        vec3 tint = acid(time_f * 0.03 + hAir * 0.9 + layer * 0.11 + oldest.b * 0.2);
        float w = pow(0.81, layer) * (1.0 + hAir * 1.3 + hMid * 0.7);
        accum += cached * tint * w;
        wsum += w;
    }

    accum /= wsum;
    float sheet = smoothstep(0.4, 1.0, abs(cos(uv.y * 32.0 - time_f * 3.8 + histWet * 10.0)));
    accum += acid(uv.x * 0.25 + histWind + time_f * 0.07) * sheet * (0.06 + amp_smooth * 0.20);
    accum = mix(accum, accum.rbg, smoothstep(0.84, 1.0, amp_peak) * 0.14);
    color = vec4(clamp(accum, 0.0, 1.0), 1.0);
}