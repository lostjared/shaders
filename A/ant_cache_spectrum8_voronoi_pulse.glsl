#version 330 core
// ant_cache_spectrum8_voronoi_pulse
// Voronoi cells where each cell's brightness pulses with a unique spectrum slot
// Audio history (spectrum0..7) + Frame cache history (samp,samp1..samp8) - EXTREME

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
const float PI  = 3.14159265359;

float specHist(int i, float f) {
    if (i == 0) return texture(spectrum0, f).r;
    if (i == 1) return texture(spectrum1, f).r;
    if (i == 2) return texture(spectrum2, f).r;
    if (i == 3) return texture(spectrum3, f).r;
    if (i == 4) return texture(spectrum4, f).r;
    if (i == 5) return texture(spectrum5, f).r;
    if (i == 6) return texture(spectrum6, f).r;
    return texture(spectrum7, f).r;
}

vec4 cacheHist(int i, vec2 uv) {
    if (i == 0) return texture(samp,  uv);
    if (i == 1) return texture(samp1, uv);
    if (i == 2) return texture(samp2, uv);
    if (i == 3) return texture(samp3, uv);
    if (i == 4) return texture(samp4, uv);
    if (i == 5) return texture(samp5, uv);
    if (i == 6) return texture(samp6, uv);
    if (i == 7) return texture(samp7, uv);
    return texture(samp8, uv);
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
