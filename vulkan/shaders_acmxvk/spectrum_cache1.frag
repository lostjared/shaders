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
#define history_head int(ext.u3.x)
#define iResolution ext.u0.zw
#define time_f ext.u2.y

// Spectrum Cache 1 — Frequency-Layered Echoes
// Each cache frame is weighted by a different frequency band from the
// spectrum, so bass drives the oldest echoes and treble drives the newest.
// Moving objects leave trails whose color intensity is sculpted by audio.
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
layout(set = 0, binding = 3) uniform sampler1D spectrum;



vec4 sampleCache(int idx, vec2 uv) {
    if (idx == 0) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(0))));
    if (idx == 1) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(1))));
    if (idx == 2) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(2))));
    if (idx == 3) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(3))));
    if (idx == 4) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(4))));
    if (idx == 5) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(5))));
    if (idx == 6) return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(6))));
    return texture(history, vec3(uv, float(CACHE_HISTORY_LAYER(7))));
}

void main(void) {
    vec4 current = texture(samp, tc);

    // Sample 8 frequency bands — low to high
    float bands[8];
    bands[0] = texture(spectrum, 0.03).r;  // sub-bass
    bands[1] = texture(spectrum, 0.10).r;  // bass
    bands[2] = texture(spectrum, 0.18).r;  // low-mid
    bands[3] = texture(spectrum, 0.28).r;  // mid
    bands[4] = texture(spectrum, 0.40).r;  // upper-mid
    bands[5] = texture(spectrum, 0.55).r;  // presence
    bands[6] = texture(spectrum, 0.72).r;  // treble
    bands[7] = texture(spectrum, 0.90).r;  // air

    // Each cache frame drifts in a direction modulated by its band energy
    vec3 accum = vec3(0.0);
    float totalW = 0.0;

    for (int i = 0; i < 8; i++) {
        float energy = bands[i];
        float age = float(i + 1);

        // Drift offset driven by spectrum energy and time
        float angle = time_f * 0.3 + float(i) * 0.785;
        vec2 drift = vec2(cos(angle), sin(angle)) * energy * 0.015;

        vec4 cached = sampleCache(i, tc + drift);

        // Weight: base decay * spectrum energy boost
        float w = (1.0 / (1.0 + age * 0.35)) * (0.3 + energy * 0.7);
        accum += cached.rgb * w;
        totalW += w;
    }

    accum /= max(totalW, 0.001);

    // Tint the echo accumulation based on dominant bass/treble balance
    float bassEnergy = (bands[0] + bands[1]) * 0.5;
    float trebleEnergy = (bands[6] + bands[7]) * 0.5;
    vec3 tint = mix(vec3(1.0, 0.7, 0.5), vec3(0.5, 0.8, 1.2), trebleEnergy / max(bassEnergy + trebleEnergy, 0.01));
    accum *= tint;

    // Blend: current dominates, spectrum-driven echoes add depth
    float echoMix = 0.45 + 0.2 * bassEnergy;
    color = vec4(mix(current.rgb, max(current.rgb, accum), echoMix), 1.0);
}
