#version 330 core
// color_trails_cache_spectrum
// Audio-reactive cache trails that preserve the source colors without palette shifts or channel distortion.

#ifndef SIZE
#define SIZE 8
#endif

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

vec4 cacheHist(int i, vec2 uv) {
    return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(i))));
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

vec2 trailField(vec2 uv, float bass, float mid, float treble, float air, vec3 oldest, float layer) {
    float ribbon = sin(uv.y * (16.0 + treble * 10.0) + time_f * (1.6 + air) + layer * 0.7);
    float cross = cos(uv.x * (10.0 + bass * 8.0) - time_f * (1.2 + mid) - layer * 0.5);
    vec2 flow = vec2(ribbon, cross);
    flow += vec2(oldest.r - oldest.b, oldest.g - oldest.r) * 0.7;
    return flow * (0.010 + bass * 0.020 + mid * 0.020 + air * 0.015);
}

void main() {
    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    float bass = texture(spectrum0, 0.03).r;
    float mid = texture(spectrum0, 0.18).r;
    float treble = texture(spectrum0, 0.52).r;
    float air = texture(spectrum0, 0.86).r;

    float histBass = 0.0;
    float histMid = 0.0;
    float histTreble = 0.0;
    float histAir = 0.0;
    for (int i = 0; i < 8; i++) {
        histBass += specHist(i, 0.03);
        histMid += specHist(i, 0.18);
        histTreble += specHist(i, 0.52);
        histAir += specHist(i, 0.86);
    }
    histBass /= 8.0;
    histMid /= 8.0;
    histTreble /= 8.0;
    histAir /= 8.0;

    vec2 oldestWarp = vec2(
        sin(time_f * 0.32 + uv.y * 7.0 + histMid * 4.0),
        cos(time_f * 0.24 - uv.x * 6.0 + histTreble * 5.0)
    ) * (0.010 + histAir * 0.025);
    vec3 oldest = texture(history, vec3(tc + oldestWarp, float(CACHE_HISTORY_LAYER(SIZE - 1)))).rgb;

    vec3 live = texture(samp, tc + trailField(uv, bass, mid, treble, air, oldest, 0.0)).rgb;

    vec3 accum = live;
    float wsum = 1.0;
    for (int i = 0; i < SIZE; i++) {
        float layer = float(i + 1);
        float hBass = specHist(i, 0.03);
        float hMid = specHist(i, 0.18);
        float hTreble = specHist(i, 0.52);
        float hAir = specHist(i, 0.86);

        vec2 drift = trailField(uv, hBass, hMid, hTreble, hAir, oldest, layer);
        drift += vec2(cos(layer * 0.6 + time_f * 0.4), sin(layer * 0.7 - time_f * 0.3)) * (0.006 + hBass * 0.020);

        vec3 cached = cacheHist(i, tc + drift).rgb;
        float w = pow(0.81, layer) * (1.0 + hTreble * 0.9 + hAir * 0.3);
        accum += cached * w;
        wsum += w;
    }

    accum /= wsum;

    // Use a radial pulse instead of a y-axis stripe term to avoid
    // horizontal bars sweeping across the frame.
    float radius = length(uv);
    float trailAccent = 0.5 + 0.5 * sin(time_f * 1.7 + histTreble * 4.5 - radius * 3.2);
    accum *= 0.95 + trailAccent * 0.06 + amp_smooth * 0.10;
    accum = clamp(accum, 0.0, 1.0);

    color = vec4(accum, 1.0);
}