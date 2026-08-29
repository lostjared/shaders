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

// ant_cache_spectrum8_cosmic_web
// Holographic fringe x game_ant_cosmic_web starfield twinkle + filament lattice
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

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void main() {
    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    vec3 acc = vec3(0.0);
    for (int i = 0; i < 8; i++) {
        float h  = specHist(i, 0.05 + float(i) * 0.06);
        float h2 = specHist(i, 0.55);
        float ang = float(i) * 0.4 + h2 * 3.0;
        vec2 dir = vec2(cos(ang), sin(ang));
        float fringe = sin(dot(uv, dir) * (40.0 + h * 80.0) + iTime * (1.0 + h * 4.0));
        fringe = pow(fringe * 0.5 + 0.5, 4.0);
        vec2 suv = tc + dir * fringe * 0.04 * (1.0 + h);

        vec3 c;
        c.r = cacheHist(i, suv + vec2(h * 0.08, 0.0)).r;
        c.g = cacheHist(i, suv).g;
        c.b = cacheHist(i, suv - vec2(h * 0.08, 0.0)).b;
        vec3 tint = palette(float(i) * 0.13 + h * 4.0, vec3(0.0, 0.33, 0.66));
        acc += (c + tint * fringe * 0.45) * (1.0 + h * 4.5) * pow(0.84, float(i));
    }
    acc /= 3.0;

    // Cosmic web overlay: twinkling starfield + filament sin lattice
    float bass = texture(spectrum0, 0.04).r;
    float air  = texture(spectrum0, 0.85).r;
    vec2 g = floor(tc * iResolution / 4.0);
    float hg = hash(g);
    float twinkle = step(0.972 - air * 0.02, hg) * (0.5 + 0.5 * sin(iTime * 2.0 + hg * 30.0));
    vec3 starCol = vec3(0.7, 0.85, 1.0) * twinkle * (1.0 + bass * 4.0);

    // Filaments – several sin lattices at history-driven scales
    float web = 0.0;
    for (int k = 0; k < 4; k++) {
        float s = 14.0 + float(k) * 6.0 + specHist(k * 2, 0.3) * 30.0;
        float w = sin(uv.x * s + iTime * 0.3) * sin(uv.y * s - iTime * 0.27);
        web += smoothstep(0.7, 1.0, w);
    }
    web *= 0.18;
    vec3 webCol = vec3(0.6, 0.7, 1.0) * web * (0.7 + amp_smooth);

    vec3 outc = acc + starCol + webCol;
    outc *= 1.2 + amp_smooth * 1.0;
    // gentle vignette so stars pop
    vec2 vUV = tc * (1.0 - tc.yx);
    float vig = pow(vUV.x * vUV.y * 15.0, 0.18);
    outc *= mix(0.7, 1.05, vig);

    color = vec4(clamp(outc, 0.0, 1.0), 1.0);
}
