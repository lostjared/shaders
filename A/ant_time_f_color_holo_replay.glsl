#version 330 core
// ant_time_f_color_holo_replay
// Holographic replay: 9 transparent layers stacked with chromatic offset, FFT history scanlines
// Cache (samp1..samp8) + FFT history (spectrum0..7) made visually obvious.

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

uniform float time_f;
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

// 0 -> live samp, 1..8 -> samp1..samp8 (oldest)
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

// 0 -> spectrum0 (now), 7 -> spectrum7 (oldest)
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

float histEnergy(float f) {
    float e = 0.0;
    for (int i = 0; i < 8; i++)
        e += specHist(i, f);
    return e;
}

void main() {
    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);
    float bass = texture(spectrum0, 0.03).r;
    float mid = texture(spectrum0, 0.22).r;
    float treble = texture(spectrum0, 0.58).r;
    float air = texture(spectrum0, 0.85).r;
    float E_bass = histEnergy(0.03);
    float E_mid = histEnergy(0.22);
    float E_treble = histEnergy(0.58);
    float E_air = histEnergy(0.85);

    vec3 acc = vec3(0.0);
    for (int i = 0; i < 9; i++) {
        float t = float(i);
        float h = specHist(min(i, 7), 0.1) * 5.0;
        vec2 ca = 0.005 * t * vec2(cos(time_f * 0.3 + t), sin(time_f * 0.4 + t));
        vec3 c;
        c.r = cacheHist(i, tc + ca).r;
        c.g = cacheHist(i, tc).g;
        c.b = cacheHist(i, tc - ca).b;
        vec3 tint = palette(t * 0.13 + time_f * 0.05,
                            vec3(0.0, 0.33, 0.66));
        c *= tint * (0.6 + h * 0.6);
        acc += c * pow(0.82, t);
    }
    acc /= 3.0;
    // holographic scanlines driven by oldest spectrum
    float scan = sin(tc.y * 200.0 + time_f * 4.0) * 0.5 + 0.5;
    scan = mix(0.7, 1.0, scan);
    acc *= scan;
    // FFT history bar at left edge
    if (tc.x < 0.04) {
        int row = int(clamp(floor(tc.y * 8.0), 0.0, 7.0));
        acc += palette(float(row) * 0.13, vec3(0.0, 0.33, 0.66)) * specHist(row, 0.2) * 5.0;
    }
    acc = mix(acc, 1.0 - acc, smoothstep(0.85, 1.0, amp_peak));
    acc *= 1.2 + amp_smooth;
    color = vec4(clamp(acc, 0.0, 1.0), 1.0);
}
