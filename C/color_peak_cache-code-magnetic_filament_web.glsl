#version 330 core
// Magnetic Filament Web: electrified interference ridges suspended over a reflective liquid
// surface.
in vec2 tc;
out vec4 color;
uniform sampler2D samp, samp1, samp2, samp3, samp4, samp5, samp6, samp7, samp8;
uniform sampler1D spectrum0, spectrum1, spectrum2, spectrum3, spectrum4, spectrum5, spectrum6,
    spectrum7;
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
    return .5 + .5 * cos(TAU * (x + vec3(.02, .29, .63)));
}
vec3 aces(vec3 x) {
    return clamp((x * (2.51 * x + .03)) / (x * (2.43 * x + .59) + .14), 0.0, 1.0);
}
vec4 C(int i, vec2 u) {
    if (i == 0)
        return texture(samp1, u);
    if (i == 1)
        return texture(samp2, u);
    if (i == 2)
        return texture(samp3, u);
    if (i == 3)
        return texture(samp4, u);
    if (i == 4)
        return texture(samp5, u);
    if (i == 5)
        return texture(samp6, u);
    if (i == 6)
        return texture(samp7, u);
    return texture(samp8, u);
}
float S(int i, float f) {
    if (i == 0)
        return texture(spectrum1, f).r;
    if (i == 1)
        return texture(spectrum2, f).r;
    if (i == 2)
        return texture(spectrum3, f).r;
    if (i == 3)
        return texture(spectrum4, f).r;
    if (i == 4)
        return texture(spectrum5, f).r;
    if (i == 5)
        return texture(spectrum6, f).r;
    return texture(spectrum7, f).r;
}
float H(vec2 p, vec2 o, float b, float m) {
    vec2 q = p - o;
    float r = length(q), a = atan(q.y, q.x);
    float f1 = sin(q.x * 22.0 + sin(q.y * 7.0 - time_f) * 5.0 + time_f * 2.0);
    float f2 = sin((q.x * .55 + q.y) * 19.0 + cos(q.x * 8.0 + time_f * .8) * 4.0 - time_f * 2.6);
    float web = pow(1.0 - abs(f1 * f2), 5.0);
    float ring = sin(r * (26.0 + b * 18.0) - time_f * 6.0);
    float coil = sin(a * (5.0 + floor(amp_high * 4.0)) - r * (16.0 - m * 5.0) - time_f * 3.0);
    return web * .24 + ring * .1 + coil * .09;
}
void main() {
    vec2 res = max(iResolution, vec2(1)), mu = iMouse.xy / res;
    float ar = res.x / res.y, b = texture(spectrum0, .03).r, m = texture(spectrum0, .22).r,
          t = texture(spectrum0, .58).r, a = texture(spectrum0, .8).r;
    vec2 p = (tc - .5) * vec2(ar, 1), o = (iMouse.z > 0.0) ? (mu - .5) * vec2(ar, 1) : vec2(0);
    float e = 2.0 / max(max(res.x, res.y), 340.0), h = H(p, o, b, m);
    vec2 g = vec2(H(p + vec2(e, 0), o, b, m) - h, H(p + vec2(0, e), o, b, m) - h) / e;
    vec3 n = normalize(vec3(-g * .23, 1));
    vec2 uv = mir(tc + n.xy * (.028 + amp_low * .05));
    float d = .005 + t * .02;
    vec3 tex = vec3(texture(samp, mir(uv + n.xy * d)).r, texture(samp, uv).g,
                    texture(samp, mir(uv - n.xy * d)).b);
    vec3 v = normalize(vec3(-p * .12, 1.7)), l = normalize(vec3(-.4, .65, .9));
    float sp = pow(max(dot(n, normalize(v + l)), 0.0), 65.0),
          fr = pow(1.0 - max(dot(n, v), 0.0), 5.0);
    float wire = pow(clamp(h * 2.4, 0.0, 1.0), 5.0);
    vec3 cur = mix(tex, pal(h * 1.8 + b) * (.35 + dot(tex, vec3(.333))), .48);
    cur *= .2 + .5 * max(dot(n, l), 0.0);
    cur += pal(h + time_f * .12) * (wire * (1.2 + a * 2.0) + sp * 2.0 + fr * .6);
    vec3 acc = cur;
    float ws = 1.0;
    vec2 center = (iMouse.z > 0.0) ? mu : vec2(.5);
    for (int i = 0; i < 8; i++) {
        float k = float(i + 1), hb = S(i, .03), hm = S(i, .22), ht = S(i, .58);
        vec2 f = tc - center;
        f += vec2(sin(f.y * 12.0 + k), cos(f.x * 10.0 - k)) * (.002 + hm * .01) * k;
        f = R((ht - .25) * .035 * k) * f * pow(max(.975 - hb * .075, .25), k) + center;
        float w = pow(.74, k);
        acc += C(i, mir(f)).rgb * pal(k * .055 + h * .12) * w;
        ws += w;
    }
    acc /= ws;
    acc = mix(acc, 1.0 - acc, smoothstep(.9, 1.0, amp_peak));
    color = vec4(aces(acc * (.95 + amp_smooth * .3)), texture(samp, uv).a);
}
