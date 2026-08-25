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
#define iTime ext.u0.y
#define spectrum_history_head int(ext.audio_history.x)
#define spectrum_history_size int(ext.audio_history.y)

// ant_cache_spectrum8_tremor_storm
// Holographic fringe x tremor2 sine quake distortion driven by spectrum bands
// Audio history (spectrum0..7) + Frame cache history (samp,samp1..samp8) - EXTREME
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
    if (i == 0) return texture(spectrum0, f).r;
    if (i == 1) return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(1)))).r;
    if (i == 2) return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(2)))).r;
    if (i == 3) return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(3)))).r;
    if (i == 4) return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(4)))).r;
    if (i == 5) return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(5)))).r;
    if (i == 6) return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(6)))).r;
    return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(7)))).r;
}

vec4 cacheHist(int i, vec2 uv) {
    if (i == 0) return texture(samp,  uv);
    if (i == 1) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(0))));
    if (i == 2) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(1))));
    if (i == 3) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(2))));
    if (i == 4) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(3))));
    if (i == 5) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(4))));
    if (i == 6) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(5))));
    if (i == 7) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(6))));
    return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(7))));
}

vec3 palette(float t, vec3 d) {
    return 0.5 + 0.5 * cos(TAU * (vec3(1.0) * t + d));
}

float pingPong(float t, float maxT) {
    return abs(mod(t, 2.0 * maxT) - maxT);
}

vec2 tremor(vec2 uv, float freq, float amp, float phase) {
    float x = sin(uv.y * freq + iTime * 5.0 + phase) * amp;
    float y = cos(uv.x * freq + iTime * 5.0 + phase) * amp;
    return uv + vec2(x, y);
}

void main() {
    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    vec3 acc = vec3(0.0);
    for (int i = 0; i < 8; i++) {
        float h  = specHist(i, 0.05 + float(i) * 0.06);
        float h2 = specHist(i, 0.55);
        float bass = specHist(i, 0.04);

        float intervalFactor = pingPong(iTime, 2.0) / 2.0;
        float ampQ = (0.015 + bass * 0.08) * intervalFactor;
        vec2 suv = tremor(tc, 18.0 + h * 50.0, ampQ, float(i) * 0.7);

        // Holographic fringe
        float ang = float(i) * 0.4 + h2 * 3.0;
        vec2 dir = vec2(cos(ang), sin(ang));
        float fringe = sin(dot(uv, dir) * (40.0 + h * 80.0) + iTime * (1.0 + h * 4.0));
        fringe = pow(fringe * 0.5 + 0.5, 4.0);
        suv += dir * fringe * 0.06 * (1.0 + bass * 3.0);

        vec3 c;
        c.r = cacheHist(i, fract(suv) + vec2(h * 0.1, 0.0)).r;
        c.g = cacheHist(i, fract(suv)).g;
        c.b = cacheHist(i, fract(suv) - vec2(h * 0.1, 0.0)).b;

        vec3 tint = palette(float(i) * 0.13 + h * 4.0, vec3(0.0, 0.33, 0.66));
        acc += (c + tint * fringe * 0.6) * (1.0 + h * 5.0 + bass * 4.0) * pow(0.82, float(i));
    }
    acc /= 3.0;
    acc *= 1.3 + amp_peak * 1.4;
    color = vec4(clamp(acc, 0.0, 1.0), 1.0);
}
