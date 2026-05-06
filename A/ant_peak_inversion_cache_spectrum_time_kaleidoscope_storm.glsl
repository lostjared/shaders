#version 330 core
// ant_peak_inversion_cache_spectrum_time_kaleidoscope_storm
// Kaleidoscope where each slice is a different cache frame and FFT slot, 5x intensity
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
    float a = atan(uv.y, uv.x);
    int slices = 6 + int(floor(treble * 12.0));
    float seg = TAU / float(slices);
    float aa = abs(mod(a, seg) - seg * 0.5);
    vec2 kuv = vec2(cos(aa), sin(aa)) * r;

    vec3 acc = vec3(0.0);
    float wsum = 0.0;
    for (int i = 0; i < 9; i++) {
        float h = specHist(min(i, 7), 0.05 + float(i) * 0.05) * 5.0;
        float h2 = specHist(min(i, 7), 0.55) * 5.0;
        float rot = iTime * 0.4 + float(i) * 0.7 + h * 4.0;
        float cs = cos(rot), sn = sin(rot);
        vec2 p = vec2(kuv.x * cs - kuv.y * sn, kuv.x * sn + kuv.y * cs) * (1.0 - h * 0.05);
        vec2 suv = p / vec2(aspect, 1.0) + 0.5;
        vec3 c = cacheHist(i, suv).rgb;
        c *= acid(float(i) * 0.13 + h2 * 0.5) * (1.0 + h * 5.0);
        float w = pow(0.86, float(i)) * (1.0 + h2);
        acc += c * w;
        wsum += w;
    }
    acc /= wsum;
    acc = mix(acc, 1.0 - acc, smoothstep(0.65, 1.0, amp_peak));
    color = vec4(clamp(acc * (1.0 + E_bass * 0.5), 0.0, 1.0), 1.0);
}
