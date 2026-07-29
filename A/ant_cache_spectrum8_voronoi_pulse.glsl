#version 330 core
// ant_cache_spectrum8_voronoi_pulse
// Voronoi cells where each cell's brightness pulses with a unique spectrum slot
// Audio history (spectrum0..7) + Frame cache history (samp,samp1..samp8) - EXTREME

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

uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;

const float TAU = 6.28318530718;
const float PI  = 3.14159265359;

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

vec3 palette(float t, vec3 d) {
    return 0.5 + 0.5 * cos(TAU * (vec3(1.0, 1.0, 1.0) * t + d));
}

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float energy() {
    float e = 0.0;
    for (int i = 0; i < 8; i++) {
        e += specHist(i, 0.05) + specHist(i, 0.25) + specHist(i, 0.6);
    }
    return e / 24.0;
}

void main() {
    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);
    float bass   = texture(spectrum0, 0.03).r;
    float mid    = texture(spectrum0, 0.22).r;
    float treble = texture(spectrum0, 0.58).r;
    float air    = texture(spectrum0, 0.85).r;
    float e      = energy();

    vec2 g = floor(uv * 6.0);
    vec2 f = fract(uv * 6.0);
    float minD = 10.0;
    vec2 minP = vec2(0.0);
    int minI = 0;
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            vec2 o = vec2(float(x), float(y));
            vec2 cell = g + o;
            float t = iTime * 0.5 + hash(cell) * 6.0;
            vec2 p = o + 0.5 + 0.4 * vec2(sin(t), cos(t * 1.3));
            float d = length(p - f);
            if (d < minD) { minD = d; minP = cell; minI = int(mod(hash(cell) * 8.0, 8.0)); }
        }
    }
    float h = specHist(minI, 0.05 + hash(minP + 1.0) * 0.7);
    float h2 = specHist(minI, 0.5);
    float edge = smoothstep(0.0, 0.1, minD);
    vec3 c = cacheHist(minI, tc).rgb;
    vec3 tint = palette(hash(minP) + h, vec3(0.0, 0.33, 0.66));
    vec3 acc = c * (0.4 + h * 4.0) + tint * (1.0 - edge) * (1.0 + h * 5.0);

    // ambient layer mix
    for (int i = 0; i < 4; i++) {
        acc += cacheHist(i + 1, tc + vec2(0.01 * float(i), 0.0)).rgb * 0.15 * specHist(i, 0.3);
    }
    color = vec4(clamp(acc, 0.0, 1.0), 1.0);
}
