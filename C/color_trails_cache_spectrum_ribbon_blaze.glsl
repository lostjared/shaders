#version 330 core
// color_trails_cache_spectrum_ribbon_blaze
// Flame-trail ribbons with diagonal streaking and bright cache combustion on peaks.

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
    return 0.5 + 0.5 * cos(TAU * (vec3(1.0, 0.7, 0.4) * t + vec3(0.00, 0.14, 0.28)));
}

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

vec2 ribbonField(vec2 uv, float bass, float mid, float treble, float air, vec3 oldest, float layer) {
    float slash = sin((uv.x + uv.y) * 18.0 - time_f * 3.0 + layer * 0.8 + treble * 9.0);
    float lift = cos(uv.y * 25.0 - time_f * 2.2 - layer + air * 11.0);
    vec2 field = vec2(slash + lift * 0.4, lift - slash * 0.2);
    field += vec2(oldest.r - oldest.g, oldest.r - oldest.b) * 1.2;
    return field * (0.015 + bass * 0.030 + treble * 0.018);
}

void main() {
    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    float bass = texture(spectrum0, 0.02).r;
    float mid = texture(spectrum0, 0.16).r;
    float treble = texture(spectrum0, 0.48).r;
    float air = texture(spectrum0, 0.78).r;

    float histBass = 0.0;
    float histAir = 0.0;
    for (int i = 0; i < 8; i++) {
        histBass += specHist(i, 0.02);
        histAir += specHist(i, 0.78);
    }
    histBass /= 8.0;
    histAir /= 8.0;

    vec2 oldestWarp = vec2(
                          cos(time_f * 0.3 + uv.y * 12.0 + histBass * 8.0),
                          sin(time_f * 0.33 + uv.x * 8.0 + histAir * 10.0)) *
                      (0.011 + histBass * 0.025 + histAir * 0.020);
    vec3 oldest = texture(samp8, tc + oldestWarp).rgb;

    vec2 liveWarp = ribbonField(uv, bass, mid, treble, air, oldest, 0.0);
    vec3 live = texture(samp, tc + liveWarp).rgb;
    live = mix(live, live.rgb * acid(length(uv) * 0.5 + time_f * 0.10), 0.55);

    vec3 accum = live;
    float wsum = 1.0;
    for (int i = 0; i < 8; i++) {
        float layer = float(i + 1);
        float hBass = specHist(i, 0.02);
        float hMid = specHist(i, 0.16);
        float hTreble = specHist(i, 0.48);
        float hAir = specHist(i, 0.78);
        vec2 drift = ribbonField(uv, hBass, hMid, hTreble, hAir, oldest, layer);
        drift += vec2(cos(layer * 1.1 - uv.y * 3.0), sin(layer * 0.7 + uv.x * 5.0)) * (0.009 + hAir * 0.030);
        vec3 cached = cacheHist(i, tc + drift).rgb;
        vec3 tint = acid(layer * 0.08 + hBass * 0.7 + hTreble * 0.6 + oldest.r * 0.4);
        float w = pow(0.77, layer) * (1.0 + hBass * 1.5 + hTreble * 0.8);
        accum += cached * tint * w;
        wsum += w;
    }

    accum /= wsum;
    float flare = smoothstep(0.5, 1.0, abs(sin((uv.x + uv.y) * 30.0 - time_f * 3.2 + histAir * 12.0)));
    accum += vec3(1.0, 0.45, 0.1) * flare * (0.05 + amp_smooth * 0.30 + amp_peak * 0.20);
    accum = mix(accum, vec3(1.0) - accum, smoothstep(0.90, 1.0, amp_peak) * 0.12);
    color = vec4(clamp(accum, 0.0, 1.0), 1.0);
}