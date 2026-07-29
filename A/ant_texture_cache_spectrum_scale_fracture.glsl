#version 330 core
// ant_texture_cache_spectrum_scale_fracture
// Trail-cache shader scaled by SIZE (--texture-cache-size).
// Uses textures[0..SIZE-1] for cached frames and spectrum0..7 for audio.

#ifndef SIZE
#define SIZE 8
#endif

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

uniform float time_f;
uniform float amp_peak;
uniform float amp_smooth;
uniform vec2 iResolution;

const float TAU = 6.28318530718;

float specHist(int i, float f) {
    int j = i & 7;
    if (j == 0) return texture(spectrum0, f).r;
    if (j == 1) return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(1)))).r;
    if (j == 2) return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(2)))).r;
    if (j == 3) return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(3)))).r;
    if (j == 4) return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(4)))).r;
    if (j == 5) return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(5)))).r;
    if (j == 6) return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(6)))).r;
    return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(7)))).r;
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
    vec2 cell = floor(uv * (8.0 + age * 6.0));
    float h = hash12(cell + layer);
    return (vec2(fract(h * 13.7), fract(h * 7.3)) - 0.5) * (0.010 + age * 0.025);

}

vec3 styleColor(vec3 cached, float layer, float age, float hB, float hT) {
    return cached * (0.92 + 0.10 * step(0.6, hash12(vec2(layer, hT * 50.0))));

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

    vec3 oldest = texture(history, vec3(tc, float(CACHE_HISTORY_LAYER(SIZE - 1)))).rgb;

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
        vec3 cached = texture(history, vec3(tc + drift, float(CACHE_HISTORY_LAYER(i)))).rgb;
        cached = styleColor(cached, layer, age, hB, hT);

        float w = pow(decay, layer) * (1.0 + hT * 0.9 + hA * 0.3);
        accum += cached * w;
        wsum  += w;
    }
    accum /= wsum;

    accum *= 0.95 + amp_smooth * 0.10;


    color = vec4(clamp(accum, 0.0, 1.0), 1.0);
}
