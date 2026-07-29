#version 330 core
// ant_peak_inversion_cache_spectrum_time_hyperspace_tunnel
// Hyperspace tunnel: each ring is an older frame, zoom/rot driven 5x by FFT history
// EXTREME 5x history feedback - cache (samp..samp8) + FFT history (spectrum0..7)

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

vec3 acid(float t) {
    return 0.5 + 0.5 * cos(TAU * (vec3(1.0, 1.0, 0.5) * t + vec3(0.3, 0.2, 0.2)));
}

vec3 palette(float t, vec3 d) {
    return 0.5 + 0.5 * cos(TAU * (vec3(1.0) * t + d));
}

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Cache lookup: 0 -> live (samp), 1..8 -> samp1..samp8 (oldest)
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

// FFT history: 0 -> spectrum0 (now), 7 -> spectrum7 (oldest)
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

// Total band energy across all 8 history slots (5x amplification baseline).
float histEnergy(float f) {
    float e = 0.0;
    for (int i = 0; i < 8; i++) e += specHist(i, f);
    return e * 5.0;
}

void main() {
    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);
    float bass   = texture(spectrum0, 0.03).r;
    float mid    = texture(spectrum0, 0.22).r;
    float treble = texture(spectrum0, 0.58).r;
    float air    = texture(spectrum0, 0.85).r;

    // Aggregated 5x energies
    float E_bass   = histEnergy(0.03);
    float E_mid    = histEnergy(0.22);
    float E_treble = histEnergy(0.58);
    float E_air    = histEnergy(0.85);

    float r = length(uv);
    vec3 acc = vec3(0.0);
    for (int i = 0; i < 9; i++) {
        float h = specHist(min(i, 7), 0.04) * 5.0;
        float h2 = specHist(min(i, 7), 0.6) * 5.0;
        float zoom = max(0.05, 1.0 - 0.10 * float(i) - h * 0.5);
        float rot = float(i) * 0.3 + h2 * 5.0 + iTime * 0.5;
        float cs = cos(rot), sn = sin(rot);
        vec2 p = uv / zoom;
        p = vec2(p.x * cs - p.y * sn, p.x * sn + p.y * cs);
        vec2 suv = p / vec2(aspect, 1.0) + 0.5;
        vec3 c = cacheHist(i, suv).rgb;
        c *= acid(float(i) * 0.1 + r - iTime * 0.2) * (0.5 + h * 5.0);
        acc += c * pow(0.78, float(i)) * (1.0 + h2 * 2.0);
    }
    acc /= 3.0;
    acc = mix(acc, 1.0 - acc, smoothstep(0.7, 0.95, amp_peak));
    color = vec4(clamp(acc, 0.0, 1.0), 1.0);
}
