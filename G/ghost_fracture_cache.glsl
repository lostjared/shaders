#version 330 core
// Ghost Fracture — Each cache frame is shown through a different
// geometric distortion, creating fractured mirror ghosts that
// overlap in a kaleidoscopic time-delay effect.

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

uniform vec2 iResolution;
uniform float time_f;

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
    if (idx == 0) return texture(samp1, uv);
    if (idx == 1) return texture(samp2, uv);
    if (idx == 2) return texture(samp3, uv);
    if (idx == 3) return texture(samp4, uv);
    if (idx == 4) return texture(samp5, uv);
    if (idx == 5) return texture(samp6, uv);
    if (idx == 6) return texture(samp7, uv);
    return texture(samp8, uv);
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
