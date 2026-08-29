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

// Ghost Fracture — Each cache frame is shown through a different
// geometric distortion, creating fractured mirror ghosts that
// overlap in a kaleidoscopic time-delay effect.
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



vec2 rotate2D(vec2 p, float a) {
    float s = sin(a), c = cos(a);
    return vec2(p.x * c - p.y * s, p.x * s + p.y * c);
}

// Each cache frame gets a unique distortion
vec2 fracture(vec2 uv, int layer) {
    vec2 centered = uv - 0.5;
    float t = time_f * 0.3 + float(layer) * 0.8;

    if (layer == 0) {
        // Horizontal flip ghost
        centered.x = -centered.x;
    } else if (layer == 1) {
        // Rotated ghost
        centered = rotate2D(centered, t * 0.5);
    } else if (layer == 2) {
        // Scaled-down echo
        centered *= 1.3;
    } else if (layer == 3) {
        // Diagonal mirror
        centered = vec2(centered.y, centered.x);
    } else if (layer == 4) {
        // Swirl distortion
        float r = length(centered);
        float a = atan(centered.y, centered.x) + r * 3.0 * sin(t);
        centered = vec2(cos(a), sin(a)) * r;
    } else if (layer == 5) {
        // Vertical flip + offset
        centered.y = -centered.y;
        centered += 0.05 * vec2(sin(t * 2.0), cos(t * 1.5));
    } else if (layer == 6) {
        // Fish-eye bulge
        float r = length(centered);
        centered *= 1.0 + r * r * 2.0;
    } else {
        // Pixel scatter
        centered += 0.03 * vec2(sin(centered.y * 40.0 + t * 5.0),
                                cos(centered.x * 40.0 + t * 4.0));
    }

    return centered + 0.5;
}

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

    // Cycle which layers are visible — 4 of 8 at a time
    int cycle = int(time_f * 0.8) % 8;

    vec3 ghostAccum = vec3(0.0);
    float totalW = 0.0;

    for (int i = 0; i < 8; i++) {
        // Staggered visibility — each layer pulses in and out
        float phase = sin(time_f * 1.5 + float(i) * 0.785) * 0.5 + 0.5;
        float weight = phase * (1.0 - float(i) * 0.1);
        if (weight < 0.05) continue;

        vec2 fracturedUV = fracture(tc, (i + cycle) % 8);
        vec4 cached = sampleCache(i, fracturedUV);

        // Tint each layer uniquely
        float hue = float(i) / 8.0 + time_f * 0.05;
        vec3 tint = vec3(
            0.7 + 0.3 * cos(hue * 6.28),
            0.7 + 0.3 * cos((hue + 0.33) * 6.28),
            0.7 + 0.3 * cos((hue + 0.66) * 6.28)
        );

        ghostAccum += cached.rgb * tint * weight;
        totalW += weight;
    }

    if (totalW > 0.0) ghostAccum /= totalW;

    // Screen blend: brightens without blowing out
    vec3 result = vec3(1.0) - (vec3(1.0) - current.rgb) * (vec3(1.0) - ghostAccum * 0.6);

    color = vec4(result, 1.0);
}
