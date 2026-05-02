#version 330 core
// color_trails_cache_spectrum_ribbon_comet
// Audio-reactive comet ribbons with cache feedback pulled through the oldest history buffer.

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

vec3 acid(float t) {
    vec3 a = vec3(0.5);
    vec3 b = vec3(0.5);
    vec3 c = vec3(1.0, 0.85, 0.65);
    vec3 d = vec3(0.02, 0.21, 0.39);
    return a + b * cos(TAU * (c * t + d));
}

vec4 cacheHist(int i, vec2 uv) {
    if (i == 0) return texture(samp1, uv);
    if (i == 1) return texture(samp2, uv);
    if (i == 2) return texture(samp3, uv);
    if (i == 3) return texture(samp4, uv);
    if (i == 4) return texture(samp5, uv);
    if (i == 5) return texture(samp6, uv);
    if (i == 6) return texture(samp7, uv);
    return texture(samp8, uv);
}

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

vec2 ribbonField(vec2 uv, float bass, float mid, float treble, float air, vec3 oldest, float layer) {
    float xwave = sin(uv.y * 18.0 + time_f * 1.8 + layer * 0.6 + treble * 12.0);
    float ywave = cos(uv.x * 11.0 - time_f * 1.4 - layer * 0.5 + bass * 10.0);
    vec2 curl = vec2(xwave, ywave);
    curl += vec2(oldest.r - oldest.b, oldest.g - oldest.r) * 0.9;
    return curl * (0.010 + mid * 0.040 + air * 0.020);
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
        sin(time_f * 0.35 + uv.y * 7.0 + histMid * 5.0),
        cos(time_f * 0.27 - uv.x * 6.0 + histTreble * 6.0)
    ) * (0.012 + histAir * 0.030);
    vec3 oldest = texture(samp8, tc + oldestWarp).rgb;

    vec2 liveWarp = ribbonField(uv, bass, mid, treble, air, oldest, 0.0);
    float chroma = 0.003 + treble * 0.025;
    vec3 live;
    live.r = texture(samp, tc + liveWarp + vec2(chroma, 0.0)).r;
    live.g = texture(samp, tc + liveWarp).g;
    live.b = texture(samp, tc + liveWarp - vec2(chroma, 0.0)).b;
    live *= acid(length(uv) * 0.6 + time_f * 0.08 + bass * 0.8);

    vec3 accum = live;
    float wsum = 1.0;
    for (int i = 0; i < 8; i++) {
        float layer = float(i + 1);
        float hBass = specHist(i, 0.03);
        float hMid = specHist(i, 0.18);
        float hTreble = specHist(i, 0.52);
        float hAir = specHist(i, 0.86);
        vec2 drift = ribbonField(uv, hBass, hMid, hTreble, hAir, oldest, layer);
        drift += vec2(cos(layer * 0.7 + time_f * 0.5), sin(layer * 0.8 - time_f * 0.4)) * (0.008 + hBass * 0.030);
        vec3 cached = cacheHist(i, tc + drift).rgb;
        vec3 tint = acid(layer * 0.09 + hMid * 0.7 + time_f * 0.03 + oldest.g * 0.2);
        float w = pow(0.80, layer) * (1.0 + hTreble * 1.3 + hAir * 0.4);
        accum += cached * tint * w;
        wsum += w;
    }

    accum /= wsum;
    float streak = smoothstep(0.3, 1.0, abs(sin(uv.y * 22.0 + time_f * 2.6 + histTreble * 8.0)));
    accum += acid(uv.x * 0.4 + time_f * 0.12 + histBass) * streak * (0.08 + amp_smooth * 0.25);
    accum = mix(accum, vec3(1.0) - accum, smoothstep(0.82, 1.0, amp_peak) * 0.25);
    color = vec4(clamp(accum, 0.0, 1.0), 1.0);
}