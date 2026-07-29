#version 330 core
// Ferrofluid Ripple Cathedral: magnetic spikes, moving ripple emitters, and chrome history vaults.
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
uniform float time_f, amp_peak, amp_smooth, amp_low, amp_mid, amp_high;
uniform vec2 iResolution;
uniform vec4 iMouse;
const float TAU = 6.28318530718;

vec2 mirrorUV(vec2 u) {
    return 1.0 - abs(mod(u, 2.0) - 1.0);
}
mat2 rot(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c);
}
vec3 pal(float x) {
    return 0.52 + 0.48 * cos(TAU * (x + vec3(0.02, 0.34, 0.69)));
}
vec3 tone(vec3 x) {
    return clamp((x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14), 0.0, 1.0);
}
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
float noise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x),
               mix(hash(i + vec2(0, 1)), hash(i + 1.0), f.x), f.y);
}
vec4 cache(int i, vec2 u) {
    if (i == 0)
        return texture(history, vec3(u, float(CACHE_HISTORY_LAYER(0))));
    if (i == 1)
        return texture(history, vec3(u, float(CACHE_HISTORY_LAYER(1))));
    if (i == 2)
        return texture(history, vec3(u, float(CACHE_HISTORY_LAYER(2))));
    if (i == 3)
        return texture(history, vec3(u, float(CACHE_HISTORY_LAYER(3))));
    if (i == 4)
        return texture(history, vec3(u, float(CACHE_HISTORY_LAYER(4))));
    if (i == 5)
        return texture(history, vec3(u, float(CACHE_HISTORY_LAYER(5))));
    if (i == 6)
        return texture(history, vec3(u, float(CACHE_HISTORY_LAYER(6))));
    return texture(history, vec3(u, float(CACHE_HISTORY_LAYER(7))));
}
float hist(int i, float f) {
    if (i == 0)
        return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(1)))).r;
    if (i == 1)
        return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(2)))).r;
    if (i == 2)
        return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(3)))).r;
    if (i == 3)
        return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(4)))).r;
    if (i == 4)
        return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(5)))).r;
    if (i == 5)
        return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(6)))).r;
    return texture(spectrum_history, vec2(f, float(SPECTRUM_HISTORY_LAYER(7)))).r;
}
float field(vec2 p, vec2 o, float b, float m) {
    vec2 q = p - o;
    float r = length(q), a = atan(q.y, q.x);
    vec2 s1 = vec2(sin(time_f * .31), cos(time_f * .27)) * .18;
    vec2 s2 = vec2(cos(time_f * .23), sin(time_f * .37)) * .22;
    float rip = (sin(length(q - s1) * (24.0 + b * 18.0) - time_f * 6.0) +
                 sin(length(q - s2) * (20.0 + m * 14.0) - time_f * 4.7)) *
                .12;
    float vault = cos(sqrt(p.x * p.x + .006) * (14.0 + m * 6.0) - p.y * 4.0) * .13;
    float spikes = pow(abs(sin(a * (6.0 + floor(amp_high * 5.0)) - r * 18.0)), 7.0) * exp(-r * 1.7);
    return rip + vault + spikes * .32 + (noise(p * 5.0 - time_f * .12) - .5) * .18;
}
void main() {
    vec2 res = max(iResolution, vec2(1));
    float ar = res.x / res.y;
    vec2 mouse = iMouse.xy / res, o = (iMouse.z > 0.0) ? (mouse - .5) * vec2(ar, 1) : vec2(0);
    float b = texture(spectrum0, .03).r, m = texture(spectrum0, .22).r,
          t = texture(spectrum0, .58).r;
    vec2 p = (tc - .5) * vec2(ar, 1);
    float e = 2.0 / max(max(res.x, res.y), 320.0);
    float h = field(p, o, b, m);
    vec2 g = vec2(field(p + vec2(e, 0), o, b, m) - h, field(p + vec2(0, e), o, b, m) - h) / e;
    vec3 n = normalize(vec3(-g * .25, 1));
    vec2 uv = mirrorUV(tc + n.xy * (.025 + amp_low * .045));
    float d = .004 + t * .018;
    vec3 live = vec3(texture(samp, mirrorUV(uv + n.xy * d)).r, texture(samp, uv).g,
                     texture(samp, mirrorUV(uv - n.xy * d)).b);
    vec3 v = normalize(vec3(-p * .15, 1.8)), l = normalize(vec3(-.6, .7, .8));
    float spec = pow(max(dot(n, normalize(v + l)), 0.0), 45.0 + 100.0 * (1.0 - amp_high));
    float fres = pow(1.0 - max(dot(n, v), 0.0), 5.0);
    vec3 cur = mix(live, pal(h * 1.4 + b + time_f * .06) * (.35 + dot(live, vec3(.333))), .55);
    cur = cur * (.18 + .45 * max(dot(n, l), 0.0)) +
          pal(n.x * .2 + n.y * .1 + time_f * .03) * (spec * 2.2 + fres * .7);
    vec3 acc = cur;
    float wsum = 1.0;
    vec2 center = (iMouse.z > 0.0) ? mouse : vec2(.5) + n.xy * .08;
    for (int i = 0; i < 8; i++) {
        float k = float(i + 1), hb = hist(i, .03), ht = hist(i, .58);
        vec2 q = rot((.018 + ht * .11) * k) * (tc - center) * pow(max(.965 - hb * .09, .2), k) +
                 center + n.xy * .018 * k;
        float w = pow(.74, k);
        acc += cache(i, mirrorUV(q)).rgb * pal(k * .055 + h * .12) * w;
        wsum += w;
    }
    acc /= wsum;
    acc +=
        pal(h + time_f * .1) * pow(max(sin(h * 19.0 - time_f * 3.0), 0.0), 8.0) * (1.0 + amp_peak);
    acc = mix(acc, 1.0 - acc, smoothstep(.9, 1.0, amp_peak));
    color = vec4(tone(acc * (.9 + amp_smooth * .25)), texture(samp, uv).a);
}
