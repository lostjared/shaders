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

// Spectral Smear — Directional motion blur using cache frames
// The 8 history frames are sampled with progressive offset in a
// time-rotating direction, creating a smooth motion smear trail.
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

    // Smear direction rotates slowly over time
    float angle = time_f * 0.4;
    vec2 smearDir = vec2(cos(angle), sin(angle));

    // Smear length per step
    float stepSize = 0.008;

    // Accumulate smeared trail with chromatic separation
    vec3 trailR = vec3(0.0);
    vec3 trailG = vec3(0.0);
    vec3 trailB = vec3(0.0);
    float totalW = 0.0;

    for (int i = 0; i < 8; i++) {
        float age = float(i + 1);
        float w = 1.0 / (1.0 + age * 0.5);

        // Progressive offset along smear direction
        vec2 offset = smearDir * stepSize * age;

        // Chromatic separation: R/G/B get slightly different offsets
        float chromSplit = 0.002 * age;
        vec2 perpDir = vec2(-smearDir.y, smearDir.x);

        trailR += sampleCache(i, tc + offset + perpDir * chromSplit).rgb * w;
        trailG += sampleCache(i, tc + offset).rgb * w;
        trailB += sampleCache(i, tc + offset - perpDir * chromSplit).rgb * w;
        totalW += w;
    }

    trailR /= totalW;
    trailG /= totalW;
    trailB /= totalW;

    // Composite: take R from red trail, G from center trail, B from blue trail
    vec3 smeared = vec3(trailR.r, trailG.g, trailB.b);

    // Edge detection on current frame for sharp overlay
    vec2 px = 1.0 / iResolution;
    float lum = dot(current.rgb, vec3(0.299, 0.587, 0.114));
    float lumR = dot(texture(samp, tc + vec2(px.x, 0.0)).rgb, vec3(0.299, 0.587, 0.114));
    float lumU = dot(texture(samp, tc + vec2(0.0, px.y)).rgb, vec3(0.299, 0.587, 0.114));
    float edge = abs(lum - lumR) + abs(lum - lumU);
    edge = smoothstep(0.02, 0.15, edge);

    // Current frame shows through strongly on edges, smear elsewhere
    vec3 result = mix(smeared, current.rgb, 0.3 + edge * 0.5);

    color = vec4(result, 1.0);
}
