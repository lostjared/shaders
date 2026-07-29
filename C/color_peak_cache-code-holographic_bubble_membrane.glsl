#version 330 core
// Holographic Bubble Membrane: thin-film iridescence, lens ripples, and breathing feedback.
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
vec2 mir(vec2 u) {
    return 1.0 - abs(mod(u, 2.0) - 1.0);
}
mat2 R(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c);
}
vec3 film(float x, float v) {
    return .48 + .52 * cos(TAU * (x * vec3(1.0, 1.31, 1.67) + vec3(.0, .19, .43) + v * .3));
}
vec3 tone(vec3 x) {
    return clamp(x / (.85 + x), 0.0, 1.0);
}
vec4 C(int i, vec2 u) {
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
float S(int i, float f) {
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
float bubble(vec2 p, vec2 c, float r) {
    float d = length(p - c) / r;
    return sqrt(max(1.0 - d * d, 0.0));
}
float H(vec2 p, vec2 o, float b, float m) {
    vec2 c1 = o + vec2(sin(time_f * .27), cos(time_f * .31)) * .18,
         c2 = o + vec2(cos(time_f * .19), -sin(time_f * .36)) * .24;
    float domes = bubble(p, c1, .42 + b * .08) + bubble(p, c2, .31 + m * .06);
    float r = length(p - o);
    return domes * .28 + sin(r * (23.0 + b * 16.0) - time_f * 5.0) * .1 +
           sin((p.x + p.y) * 14.0 + time_f) * .04;
}
void main() {
    vec2 res = max(iResolution, vec2(1)), mu = iMouse.xy / res;
    float ar = res.x / res.y, b = texture(spectrum0, .03).r, m = texture(spectrum0, .22).r,
          t = texture(spectrum0, .58).r, a = texture(spectrum0, .8).r;
    vec2 p = (tc - .5) * vec2(ar, 1), o = (iMouse.z > 0.0) ? (mu - .5) * vec2(ar, 1) : vec2(0);
    float e = 2.0 / max(max(res.x, res.y), 360.0), h = H(p, o, b, m);
    vec2 g = vec2(H(p + vec2(e, 0), o, b, m) - h, H(p + vec2(0, e), o, b, m) - h) / e;
    vec3 n = normalize(vec3(-g * .2, 1));
    vec2 uv = mir(tc + n.xy * (.035 + amp_low * .055));
    float d = .006 + t * .02;
    vec3 tex = vec3(texture(samp, mir(uv + n.xy * d)).r, texture(samp, uv).g,
                    texture(samp, mir(uv - n.xy * d)).b);
    vec3 v = normalize(vec3(-p * .1, 1.6));
    float nv = max(dot(n, v), 0.0), rim = pow(1.0 - nv, 3.0),
          glint = pow(max(dot(n, normalize(vec3(-.5, .7, 1))), 0.0), 80.0);
    vec3 cur = mix(tex, film(h * 3.0 + time_f * .08, nv) * (.3 + dot(tex, vec3(.333))), .52) +
               film(h * 2.0, nv) * (rim * 1.3 + glint * 2.5);
    vec3 acc = cur;
    float ws = 1.0;
    vec2 center = (iMouse.z > 0.0) ? mu : vec2(.5);
    for (int i = 0; i < 8; i++) {
        float k = float(i + 1), hb = S(i, .03), hm = S(i, .22), ht = S(i, .58);
        float breathe = 1.0 + sin(time_f * .7 - k * .6) * (.012 + hb * .035);
        vec2 f = R((ht - .2) * .025 * k) * (tc - center) * pow(breathe, k) + center +
                 n.xy * (.008 + hm * .012) * k;
        float w = pow(.77, k);
        acc += C(i, mir(f)).rgb * film(k * .045 + h * .15, float(i) / 8.0) * w;
        ws += w;
    }
    acc /= ws;
    acc += film(h + time_f * .1, nv) * pow(max(sin(h * 24.0 - time_f * 2.0), 0.0), 8.0) *
           (.6 + a * 1.8);
    acc = mix(acc, 1.0 - acc, smoothstep(.92, 1.0, amp_peak));
    color = vec4(tone(acc * (1.0 + amp_smooth * .25)), texture(samp, uv).a);
}
