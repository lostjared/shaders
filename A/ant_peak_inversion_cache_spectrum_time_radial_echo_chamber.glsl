#version 330 core
// ant_peak_inversion_cache_spectrum_time_radial_echo_chamber
// Ten concentric rings of past frames - rings expand/contract 5x with FFT history
// EXTREME 5x history feedback - cache (samp..samp8) + FFT history (spectrum0..7)

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform sampler2D samp1;
uniform sampler2D samp2;
uniform sampler2D samp3;
uniform sampler2D samp4;
uniform sampler2D samp5;
uniform sampler2D samp6;
uniform sampler2D samp7;
uniform sampler2D samp8;

uniform sampler1D spectrum0;
uniform sampler1D spectrum1;
uniform sampler1D spectrum2;
uniform sampler1D spectrum3;
uniform sampler1D spectrum4;
uniform sampler1D spectrum5;
uniform sampler1D spectrum6;
uniform sampler1D spectrum7;

uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;

const float TAU = 6.28318530718;
const float PI = 3.14159265359;

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
    if (i == 0)
        return texture(samp, uv);
    if (i == 1)
        return texture(samp1, uv);
    if (i == 2)
        return texture(samp2, uv);
    if (i == 3)
        return texture(samp3, uv);
    if (i == 4)
        return texture(samp4, uv);
    if (i == 5)
        return texture(samp5, uv);
    if (i == 6)
        return texture(samp6, uv);
    if (i == 7)
        return texture(samp7, uv);
    return texture(samp8, uv);
}

// FFT history: 0 -> spectrum0 (now), 7 -> spectrum7 (oldest)
float specHist(int i, float f) {
    if (i == 0)
        return texture(spectrum0, f).r;
    if (i == 1)
        return texture(spectrum1, f).r;
    if (i == 2)
        return texture(spectrum2, f).r;
    if (i == 3)
        return texture(spectrum3, f).r;
    if (i == 4)
        return texture(spectrum4, f).r;
    if (i == 5)
        return texture(spectrum5, f).r;
    if (i == 6)
        return texture(spectrum6, f).r;
    return texture(spectrum7, f).r;
}

// Total band energy across all 8 history slots (5x amplification baseline).
float histEnergy(float f) {
    float e = 0.0;
    for (int i = 0; i < 8; i++)
        e += specHist(i, f);
    return e * 5.0;
}

void main() {
    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);
    float bass = texture(spectrum0, 0.03).r;
    float mid = texture(spectrum0, 0.22).r;
    float treble = texture(spectrum0, 0.58).r;
    float air = texture(spectrum0, 0.85).r;

    // Aggregated 5x energies
    float E_bass = histEnergy(0.03);
    float E_mid = histEnergy(0.22);
    float E_treble = histEnergy(0.58);
    float E_air = histEnergy(0.85);

    float r = length(uv);
    vec3 acc = cacheHist(0, tc).rgb * 0.2;
    for (int i = 0; i < 9; i++) {
        float h = specHist(min(i, 7), 0.04 + float(i) * 0.07) * 5.0;
        float h2 = specHist(min(i, 7), 0.5) * 5.0;
        float ringR = 0.1 + 0.08 * float(i) + h * 0.5;
        float ring = exp(-pow((r - ringR) * 15.0, 2.0));
        float zoom = max(0.05, 1.0 - 0.05 * float(i) - h * 0.5);
        vec2 p = uv / zoom;
        vec2 suv = p / vec2(aspect, 1.0) + 0.5;
        vec3 c = cacheHist(i, suv).rgb;
        vec3 tint = acid(float(i) * 0.12 + r * 2.0 + h * 0.3);
        acc += (c * 1.2 + tint * 2.0) * ring * (1.0 + h * 8.0 + h2 * 4.0);
    }
    acc *= 1.0 + amp_smooth * 1.5;
    color = vec4(clamp(acc, 0.0, 1.0), 1.0);
}
