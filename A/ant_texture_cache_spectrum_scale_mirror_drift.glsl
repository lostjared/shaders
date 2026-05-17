#version 330 core
// ant_texture_cache_spectrum_scale_mirror_drift
// Trail-cache shader scaled by SIZE (--texture-cache-size).
// Uses textures[0..SIZE-1] for cached frames and spectrum0..7 for audio.

#ifndef SIZE
#define SIZE 8
#endif

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform sampler2D textures[SIZE];

uniform sampler1D spectrum0;
uniform sampler1D spectrum1;
uniform sampler1D spectrum2;
uniform sampler1D spectrum3;
uniform sampler1D spectrum4;
uniform sampler1D spectrum5;
uniform sampler1D spectrum6;
uniform sampler1D spectrum7;

uniform float time_f;
uniform float amp_peak;
uniform float amp_smooth;
uniform vec2 iResolution;

const float TAU = 6.28318530718;

float specHist(int i, float f) {
    int j = i & 7;
    if (j == 0) return texture(spectrum0, f).r;
    if (j == 1) return texture(spectrum1, f).r;
    if (j == 2) return texture(spectrum2, f).r;
    if (j == 3) return texture(spectrum3, f).r;
    if (j == 4) return texture(spectrum4, f).r;
    if (j == 5) return texture(spectrum5, f).r;
    if (j == 6) return texture(spectrum6, f).r;
    return texture(spectrum7, f).r;
}

vec2 rot(vec2 p, float a) {
    float c = cos(a); float s = sin(a);
    return vec2(c * p.x - s * p.y, s * p.x + c * p.y);
}

float hash12(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

vec3 palette(float t, vec3 a, vec3 b, vec3 c, vec3 d) {
    return a + b * cos(TAU * (c * t + d));
}


vec2 styleDrift(vec2 uv, float layer, float age, float hB, float hM, float hT, float hA, vec3 oldest) {
    vec2 m = vec2(-uv.x, uv.y) - uv;
    return m * (age * 0.08) + vec2(sin(time_f + layer * 0.4), cos(time_f - layer * 0.3)) * (0.004 + hT * 0.012);

}

vec3 styleColor(vec3 cached, float layer, float age, float hB, float hT) {
    return cached * (0.95 + 0.07 * sin(layer * 0.6 + hT * 3.0));

}

void main() {
    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    float bass   = texture(spectrum0, 0.03).r;
    float mid    = texture(spectrum0, 0.18).r;
    float treble = texture(spectrum0, 0.52).r;
    float air    = texture(spectrum0, 0.86).r;

    float histBass = 0.0;
    float histMid = 0.0;
    float histTreble = 0.0;
    float histAir = 0.0;
    for (int i = 0; i < 8; ++i) {
        histBass   += specHist(i, 0.03);
        histMid    += specHist(i, 0.18);
        histTreble += specHist(i, 0.52);
        histAir    += specHist(i, 0.86);
    }
    histBass /= 8.0; histMid /= 8.0; histTreble /= 8.0; histAir /= 8.0;

    vec3 oldest = texture(textures[SIZE - 1], tc).rgb;

    vec3 live = texture(samp, tc + styleDrift(uv, 0.0, 0.0, bass, mid, treble, air, oldest)).rgb;

    // Soften decay for larger caches so distant frames remain visible.
    float decay = mix(0.81, 0.94, clamp(float(SIZE - 8) / 24.0, 0.0, 1.0));

    vec3 accum = live;
    float wsum = 1.0;
    for (int i = 0; i < SIZE; ++i) {
        float layer = float(i + 1);
        float age   = layer / float(SIZE);
        float hB = specHist(i, 0.03);
        float hM = specHist(i, 0.18);
        float hT = specHist(i, 0.52);
        float hA = specHist(i, 0.86);

        vec2 drift = styleDrift(uv, layer, age, hB, hM, hT, hA, oldest);
        vec3 cached = texture(textures[i], tc + drift).rgb;
        cached = styleColor(cached, layer, age, hB, hT);

        float w = pow(decay, layer) * (1.0 + hT * 0.9 + hA * 0.3);
        accum += cached * w;
        wsum  += w;
    }
    accum /= wsum;

    accum *= 0.96 + amp_smooth * 0.10;


    color = vec4(clamp(accum, 0.0, 1.0), 1.0);
}
