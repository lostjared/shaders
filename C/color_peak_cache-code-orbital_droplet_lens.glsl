#version 330 core
// Orbital Droplet Lens: orbiting liquid lenses launch acid rings and gravitational history trails.
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
vec3 pal(float x) {
    return .5 + .5 * cos(TAU * (x + vec3(.0, .33, .68)));
}
vec3 aces(vec3 x) {
    return clamp((x * (2.51 * x + .03)) / (x * (2.43 * x + .59) + .14), 0.0, 1.0);
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
vec2 orb(float phase, float rad) {
    return vec2(cos(time_f * .45 + phase), sin(time_f * .61 + phase)) * rad;
}
float H(vec2 p, vec2 o, float b, float m) {
    float h = 0.0;
    for (int i = 0; i < 4; i++) {
        float k = float(i), r = length(p - o - orb(k * TAU * .25, .16 + k * .035));
        h += exp(-r * r * (22.0 + m * 10.0)) * .2 +
             sin(r * (27.0 + b * 16.0) - time_f * (5.0 + k * .35)) * .045;
    }
    return h + sin(length(p - o) * 18.0 - time_f * 3.0) * .06;
}
void main() {
    vec2 res = max(iResolution, vec2(1)), mu = iMouse.xy / res;
    float ar = res.x / res.y, b = texture(spectrum0, .03).r, m = texture(spectrum0, .22).r,
          t = texture(spectrum0, .58).r, a = texture(spectrum0, .8).r;
    vec2 p = (tc - .5) * vec2(ar, 1), o = (iMouse.z > 0.0) ? (mu - .5) * vec2(ar, 1) : vec2(0);
    float e = 2.0 / max(max(res.x, res.y), 340.0), h = H(p, o, b, m);
    vec2 g = vec2(H(p + vec2(e, 0), o, b, m) - h, H(p + vec2(0, e), o, b, m) - h) / e;
    vec3 n = normalize(vec3(-g * .23, 1));
    vec2 grav = vec2(0);
    for (int i = 0; i < 4; i++) {
        vec2 d = p - o - orb(float(i) * TAU * .25, .16 + float(i) * .035);
        grav -= d / (dot(d, d) + .018) * .002;
    }
    vec2 uv = mir(tc + n.xy * (.025 + amp_low * .045) + grav * (1.0 + b));
    float d = .005 + t * .02;
    vec3 tex = vec3(texture(samp, mir(uv + n.xy * d)).r, texture(samp, uv).g,
                    texture(samp, mir(uv - n.xy * d)).b);
    vec3 v = normalize(vec3(-p * .1, 1.7));
    float fr = pow(1.0 - max(dot(n, v), 0.0), 5.0),
          sp = pow(max(dot(n, normalize(vec3(.4, .7, 1))), 0.0), 75.0);
    vec3 cur = mix(tex, pal(h * 1.8 + b) * (.35 + dot(tex, vec3(.333))), .5) +
               pal(n.x * .3 + n.y * .2 + time_f * .05) * (fr * .8 + sp * 2.3);
    vec3 acc = cur;
    float ws = 1.0;
    vec2 center = (iMouse.z > 0.0) ? mu : vec2(.5);
    for (int i = 0; i < 8; i++) {
        float k = float(i + 1), hb = S(i, .03), hm = S(i, .22), ht = S(i, .58);
        vec2 f = R((.02 + ht * .1) * k) * (tc - center) * pow(max(.972 - hb * .09, .2), k) + center;
        f += grav * (1.0 + hm) * k * .7 + orb(k * .8, .003 * k) / vec2(ar, 1);
        float w = pow(.76, k);
        acc += C(i, mir(f)).rgb * pal(k * .055 + h * .13) * w;
        ws += w;
    }
    acc /= ws;
    acc += pal(h + time_f * .12) * pow(max(sin(h * 28.0), 0.0), 8.0) * (.6 + a * 2.0);
    acc = mix(acc, 1.0 - acc, smoothstep(.91, 1.0, amp_peak));
    color = vec4(aces(acc * (.92 + amp_smooth * .3)), texture(samp, uv).a);
}
