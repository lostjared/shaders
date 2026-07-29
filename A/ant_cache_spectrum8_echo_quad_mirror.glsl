#version 330 core
// ant_cache_spectrum8_echo_quad_mirror
// Holographic fringe x echo_mirror_1 quad-flip blending across cache history
// Audio history (spectrum0..7) + Frame cache history (samp,samp1..samp8) - EXTREME

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

uniform float iTime;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;

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

void main() {
    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);

    vec3 acc = vec3(0.0);
    for (int i = 0; i < 8; i++) {
        float h  = specHist(i, 0.05 + float(i) * 0.06);
        float h2 = specHist(i, 0.55);

        // Holographic fringe shift
        float ang = float(i) * 0.4 + h2 * 3.0;
        vec2 dir = vec2(cos(ang), sin(ang));
        float fringe = sin(dot(uv, dir) * (40.0 + h * 80.0) + iTime * (1.0 + h * 4.0));
        fringe = pow(fringe * 0.5 + 0.5, 4.0);
        float shift = fringe * 0.05 * (1.0 + h);
        vec2 suv = tc + dir * shift;

        // echo_mirror quad sampling per slot
        vec2 q1 = suv;
        vec2 q2 = vec2(1.0 - suv.x, suv.y);
        vec2 q3 = vec2(suv.x, 1.0 - suv.y);
        vec2 q4 = suv * 0.5 + vec2(0.25 + 0.05 * sin(iTime + float(i)));

        vec4 c1 = cacheHist(i, q1);
        vec4 c2 = cacheHist(i, q2);
        vec4 c3 = cacheHist(i, q3);
        vec4 c4 = cacheHist((i + 1) & 7, q4);
        vec3 quad = (c1.rgb + c2.rgb + c3.rgb + c4.rgb) * 0.4;

        // chromatic split applied to quad mix
        vec3 c;
        c.r = cacheHist(i, q1 + vec2(h * 0.06, 0.0)).r;
        c.g = quad.g;
        c.b = cacheHist(i, q1 - vec2(h * 0.06, 0.0)).b;
        c.r = mix(c.r, quad.r, 0.4);
        c.b = mix(c.b, quad.b, 0.4);

        vec3 tint = palette(float(i) * 0.13 + h * 4.0, vec3(0.0, 0.33, 0.66));
        acc += (c + tint * fringe * 0.5) * (1.0 + h * 4.5) * pow(0.83, float(i));
    }
    acc /= 3.0;
    acc *= 1.3 + amp_smooth * 1.2;
    color = vec4(clamp(acc, 0.0, 1.0), 1.0);
}
