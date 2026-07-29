#version 330 core
// color_trails_cache_spectrum_ribbon_serpent
// Braided spectral ribbons that slither laterally using the oldest cache frame as a steering field.

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
    return 0.5 + 0.5 * cos(TAU * (vec3(0.95, 0.8, 0.6) * t + vec3(0.13, 0.27, 0.42)));
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
    float lane = sin((uv.y + sin(uv.x * 3.0 + time_f * 0.5) * 0.2) * 24.0 - time_f * 2.2 + layer);
    float cross = cos(uv.x * 14.0 + time_f * 1.5 + layer * 0.8 + bass * 8.0);
    vec2 field = vec2(cross, lane);
    field += vec2(oldest.b - oldest.g, oldest.r - oldest.b) * 1.1;
    return field * (0.012 + mid * 0.035 + air * 0.025 + treble * 0.010);
}

void main() {
    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    float bass = texture(spectrum0, 0.04).r;
    float mid = texture(spectrum0, 0.24).r;
    float treble = texture(spectrum0, 0.56).r;
    float air = texture(spectrum0, 0.84).r;

    float histMotion = 0.0;
    float histSpark = 0.0;
    for (int i = 0; i < 8; i++) {
        histMotion += specHist(i, 0.24);
        histSpark += specHist(i, 0.56);
    }
    histMotion /= 8.0;
    histSpark /= 8.0;

    vec2 oldestWarp = vec2(
        cos(uv.y * 9.0 + time_f * 0.4 + histSpark * 7.0),
        sin(uv.x * 8.0 - time_f * 0.3 + histMotion * 6.0)
    ) * (0.010 + histMotion * 0.035);
    vec3 oldest = texture(history, vec3(tc + oldestWarp, float(CACHE_HISTORY_LAYER(7)))).rgb;

    vec2 liveWarp = ribbonField(uv, bass, mid, treble, air, oldest, 0.0);
    vec3 live = texture(samp, tc + liveWarp).rgb;
    live = mix(live, live.bgr, 0.30 + treble * 0.25);
    live *= acid(uv.y * 0.45 + time_f * 0.11 + air * 0.5);

    vec3 accum = live;
    float wsum = 1.0;
    for (int i = 0; i < 8; i++) {
        float layer = float(i + 1);
        float hBass = specHist(i, 0.04);
        float hMid = specHist(i, 0.24);
        float hTreble = specHist(i, 0.56);
        float hAir = specHist(i, 0.84);
        vec2 drift = ribbonField(uv, hBass, hMid, hTreble, hAir, oldest, layer);
        drift += vec2(sin(layer + uv.y * 5.0), cos(layer * 1.4 + uv.x * 4.0)) * (0.010 + hBass * 0.025);
        vec3 cached = cacheHist(i, tc + drift).rgb;
        vec3 tint = acid(layer * 0.12 + hTreble * 0.8 + oldest.r * 0.3 - time_f * 0.02);
        cached = mix(cached, cached.gbr, 0.22 + hAir * 0.35);
        float w = pow(0.79, layer) * (1.0 + hMid * 1.2);
        accum += cached * tint * w;
        wsum += w;
    }

    accum /= wsum;
    float weave = smoothstep(0.2, 0.95, abs(sin(uv.y * 28.0 + uv.x * 4.0 - time_f * 2.8 + histSpark * 9.0)));
    accum += acid(time_f * 0.06 + uv.x * 0.3 + histMotion) * weave * (0.10 + amp_smooth * 0.18);
    accum = mix(accum, accum.gbr, smoothstep(0.78, 1.0, amp_peak) * 0.18);
    color = vec4(clamp(accum, 0.0, 1.0), 1.0);
}