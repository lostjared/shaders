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

// Temporal Prism — Splits each cache frame into its own color channel
// and offset direction. Moving objects leave R/G/B separated trails
// that converge and diverge over time, like light through a prism.
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

    // Three prism directions, 120 degrees apart, rotating over time
    float baseAngle = time_f * 0.6;
    vec2 dirR = vec2(cos(baseAngle), sin(baseAngle));
    vec2 dirG = vec2(cos(baseAngle + 2.094), sin(baseAngle + 2.094));
    vec2 dirB = vec2(cos(baseAngle + 4.189), sin(baseAngle + 4.189));

    // Spread amount oscillates
    float spread = 0.005 + 0.003 * sin(time_f * 0.9);

    // Accumulate each channel separately across the 8 cache frames
    float rAccum = current.r;
    float gAccum = current.g;
    float bAccum = current.b;
    float rW = 1.0, gW = 1.0, bW = 1.0;

    for (int i = 0; i < 8; i++) {
        float age = float(i + 1);
        float w = 1.0 / (1.0 + age * 0.4);
        float offset = spread * age;

        // R channel trails in dirR direction
        vec4 cR = sampleCache(i, tc + dirR * offset);
        rAccum += cR.r * w;
        rW += w;

        // G channel trails in dirG direction
        vec4 cG = sampleCache(i, tc + dirG * offset);
        gAccum += cG.g * w;
        gW += w;

        // B channel trails in dirB direction
        vec4 cB = sampleCache(i, tc + dirB * offset);
        bAccum += cB.b * w;
        bW += w;
    }

    vec3 result = vec3(rAccum / rW, gAccum / gW, bAccum / bW);

    // Subtle vignette to frame the prism effect
    float dist = length(tc - 0.5) * 1.4;
    result *= 1.0 - dist * dist * 0.3;

    color = vec4(result, 1.0);
}
