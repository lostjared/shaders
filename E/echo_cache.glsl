#version 330 core

in vec2 tc;
out vec4 color;

// Live feed and cache layers
uniform sampler2D samp;
uniform sampler2DArray history;
uniform int history_head;
#ifndef SIZE
#define SIZE 8
#endif
#ifndef CACHE_HISTORY_LAYER
#define CACHE_HISTORY_LAYER(index) ((history_head + (index)) % SIZE)
#endif
uniform float time_f;
uniform vec2 iResolution;

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


void main() {
    color = texture(samp, tc);
    vec2 tc_off = vec2(0.01, 0.01);
    for(int i = 0; i <= 6; ++i) {
        color = mix(color, sampleCache(i, tc + tc_off), 0.5);
        tc_off += vec2(0.02, 0.01);
    }
    color = clamp(color, vec4(0.0), vec4(1.0));
}
