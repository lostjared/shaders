#version 330 core
// color_trails_cache_spectrum
// Audio-reactive cache trails that preserve the source colors without palette shifts or channel distortion.

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

vec4 cacheHist(int i, vec2 uv) {
    if (i == 0)
        return texture(samp1, uv);
    if (i == 1)
        return texture(samp2, uv);
    if (i == 2)
        return texture(samp3, uv);
    if (i == 3)
        return texture(samp4, uv);
    if (i == 4)
        return texture(samp5, uv);
    if (i == 5)
        return texture(samp6, uv);
    if (i == 6)
        return texture(samp7, uv);
    return texture(samp8, uv);
}

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
                          cos(time_f * 0.24 - uv.x * 6.0 + histTreble * 5.0)) *
                      (0.010 + histAir * 0.025);
    vec3 oldest = texture(samp8, tc + oldestWarp).rgb;

    vec3 live = texture(samp, tc + trailField(uv, bass, mid, treble, air, oldest, 0.0)).rgb;

    vec3 accum = live;
    float wsum = 1.0;
    for (int i = 0; i < 8; i++) {
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

    float trailAccent = smoothstep(0.35, 1.0, abs(sin(uv.y * 20.0 + time_f * 2.1 + histTreble * 7.0)));
    accum *= 0.94 + trailAccent * 0.08 + amp_smooth * 0.10;
    accum = clamp(accum, 0.0, 1.0);

    color = vec4(accum, 1.0);
}