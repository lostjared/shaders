#version 450

layout(set = 0, binding = 1, std140) uniform SpriteExtended {
    vec4 mouse;
    vec4 u0;
    vec4 u1;
    vec4 u2;
    vec4 u3;
    vec4 custom_uniforms[16];
    vec4 audio_bands;
    vec4 audio_history;
} ext;
#define amp_peak ext.u2.w
#define amp_smooth ext.u3.w
#define history_head int(ext.u3.x)
#define iResolution ext.u0.zw
#define spectrum_history_head int(ext.audio_history.x)
#define spectrum_history_size int(ext.audio_history.y)
#define time_f ext.u2.y

// ant_texture_cache_spectrum_scale_chromatic
// Trail-cache shader scaled by SIZE (--texture-cache-size).
// Uses textures[0..SIZE-1] for cached frames and spectrum0..7 for audio.

#ifndef SIZE
#define SIZE 8
#endif
layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;
layout(set = 0, binding = 2) uniform sampler2DArray history;

#ifndef SIZE
#define SIZE 8
#endif
#ifndef CACHE_HISTORY_LAYER
#define CACHE_HISTORY_LAYER(index) ((history_head + (index)) % SIZE)
#endif
layout(set = 0, binding = 3) uniform sampler1D spectrum0;
layout(set = 0, binding = 4) uniform sampler1DArray spectrum_history;


#ifndef SPECTRUM_HISTORY_LAYER
#define SPECTRUM_HISTORY_LAYER(index) ((spectrum_history_head - ((index) % max(spectrum_history_size, 1)) + max(spectrum_history_size, 1)) % max(spectrum_history_size, 1))
#endif





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
    return vec2(cos(layer * 0.4), sin(layer * 0.5)) * (0.004 + age * 0.025 + hB * 0.020);

}

vec3 styleColor(vec3 cached, float layer, float age, float hB, float hT) {
    // Per-channel age-based offset accent
    float k = age * 0.3;
    vec3 c;
    c.r = cached.r * (1.0 + k * 0.6);
    c.g = cached.g * (1.0 - k * 0.2);
    c.b = cached.b * (1.0 - k * 0.6);
    return c;

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

    accum *= 0.96 + amp_smooth * 0.10;


    color = vec4(clamp(accum, 0.0, 1.0), 1.0);
}
