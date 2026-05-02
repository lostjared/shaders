#version 330 core
// color_trails_cache_spectrum_ribbon_aurora
// Vertical aurora curtains that smear through the cache stack and bend with historical spectrum energy.

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
    return 0.5 + 0.5 * cos(TAU * (vec3(0.7, 0.95, 0.8) * t + vec3(0.08, 0.38, 0.19)));
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
    float curtain = sin(uv.x * 10.0 + sin(uv.y * 4.0 + layer) * 3.0 + time_f * 1.1 + mid * 9.0);
    float shimmer = cos(uv.y * 20.0 - time_f * 2.4 - layer * 0.7 + air * 12.0);
    vec2 field = vec2(curtain, shimmer + curtain * 0.4);
    field += vec2(oldest.g - oldest.r, oldest.b - oldest.g) * 0.8;
    return field * (0.014 + treble * 0.025 + air * 0.030);
}

void main() {
    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    float bass = texture(spectrum0, 0.05).r;
    float mid = texture(spectrum0, 0.20).r;
    float treble = texture(spectrum0, 0.60).r;
    float air = texture(spectrum0, 0.90).r;

    float histCurtain = 0.0;
    for (int i = 0; i < 8; i++) histCurtain += specHist(i, 0.60);
    histCurtain /= 8.0;

    vec2 oldestWarp = vec2(
        sin(time_f * 0.2 + uv.y * 10.0 + histCurtain * 8.0),
        cos(time_f * 0.24 + uv.x * 7.0 - histCurtain * 5.0)
    ) * (0.013 + histCurtain * 0.028 + bass * 0.012);
    vec3 oldest = texture(samp8, tc + oldestWarp).rgb;

    vec2 liveWarp = ribbonField(uv, bass, mid, treble, air, oldest, 0.0);
    vec3 live = texture(samp, tc + liveWarp).rgb;
    live += acid(uv.y * 0.6 - time_f * 0.08 + air) * smoothstep(0.15, 0.95, abs(sin(uv.x * 14.0 + time_f + treble * 10.0))) * 0.18;

    vec3 accum = live;
    float wsum = 1.0;
    for (int i = 0; i < 8; i++) {
        float layer = float(i + 1);
        float hBass = specHist(i, 0.05);
        float hMid = specHist(i, 0.20);
        float hTreble = specHist(i, 0.60);
        float hAir = specHist(i, 0.90);
        vec2 drift = ribbonField(uv, hBass, hMid, hTreble, hAir, oldest, layer);
        drift += vec2(sin(layer * 0.5), cos(layer * 0.7 + uv.x * 6.0)) * (0.009 + hBass * 0.018 + hAir * 0.015);
        vec3 cached = cacheHist(i, tc + drift).rgb;
        vec3 tint = acid(hAir * 0.8 + layer * 0.10 + time_f * 0.04 + oldest.b * 0.25);
        float w = pow(0.82, layer) * (1.0 + hAir * 1.4 + hTreble * 0.6);
        accum += cached * tint * w;
        wsum += w;
    }

    accum /= wsum;
    float veil = smoothstep(0.45, 1.0, abs(cos(uv.x * 24.0 + histCurtain * 9.0 + time_f * 1.3)));
    accum += acid(uv.y * 0.25 + time_f * 0.05 + histCurtain) * veil * (0.07 + amp_smooth * 0.22);
    accum = mix(accum, accum.brg, smoothstep(0.86, 1.0, amp_peak) * 0.16);
    color = vec4(clamp(accum, 0.0, 1.0), 1.0);
}