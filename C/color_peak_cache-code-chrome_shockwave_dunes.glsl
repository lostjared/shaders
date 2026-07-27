#version 330 core
// Chrome Shockwave Dunes: directional metallic ridges crossed by multi-source sonic rings.
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
    return .5 + .5 * cos(TAU * (x + vec3(.12, .41, .76)));
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
    vec2 s1 = vec2(sin(time_f * .4), cos(time_f * .31)) * .25, s2 = -s1.yx * .8;
    float waves = sin(length(q - s1) * (25.0 + b * 18.0) - time_f * 7.0) +
                  sin(length(q - s2) * (21.0 + m * 12.0) - time_f * 5.0);
    float dune = sin(p.y * 13.0 + p.x * 5.0 + sin(p.x * 4.0 + time_f) * 3.0 - time_f * 1.6);
    float cut = smoothstep(.15, .9, abs(sin((p.x - p.y) * 18.0 + time_f * 2.0)));
    return waves * .1 + dune * .18 + cut * .08;
}
void main() {
    vec2 res = max(iResolution, vec2(1)), mu = iMouse.xy / res;
    float ar = res.x / res.y, b = texture(spectrum0, .03).r, m = texture(spectrum0, .22).r,
          t = texture(spectrum0, .58).r, a = texture(spectrum0, .8).r;
    vec2 p = (tc - .5) * vec2(ar, 1), o = (iMouse.z > 0.0) ? (mu - .5) * vec2(ar, 1) : vec2(0);
    float e = 2.0 / max(max(res.x, res.y), 320.0), h = H(p, o, b, m);
    vec2 g = vec2(H(p + vec2(e, 0), o, b, m) - h, H(p + vec2(0, e), o, b, m) - h) / e;
    vec3 n = normalize(vec3(-g * .24, 1));
    vec2 uv = mir(tc + n.xy * (.03 + amp_low * .05));
    float d = .004 + t * .018;
    vec3 tex = vec3(texture(samp, mir(uv + vec2(d, 0) + n.xy * d)).r, texture(samp, uv).g,
                    texture(samp, mir(uv - vec2(d, 0) - n.xy * d)).b);
    vec3 v = normalize(vec3(-p * .12, 1.8)), l = normalize(vec3(.45, .75, .8));
    float sp = pow(max(dot(n, normalize(v + l)), 0.0), 70.0),
          fr = pow(1.0 - max(dot(n, v), 0.0), 5.0);
    vec3 cur = mix(tex, pal(h * 1.8 + b) * dot(tex, vec3(.333)) * 1.4, .5) *
                   (.18 + .55 * max(dot(n, l), 0.0)) +
               pal(n.x - n.y + time_f * .04) * (sp * 2.4 + fr * .7);
    vec3 acc = cur;
    float ws = 1.0;
    vec2 center = (iMouse.z > 0.0) ? mu : vec2(.5);
    for (int i = 0; i < 8; i++) {
        float k = float(i + 1), hb = S(i, .03), hm = S(i, .22), ht = S(i, .58);
        vec2 f = tc - center;
        f.x *= 1.0 + k * (.012 + hm * .025);
        f = R((ht - .2) * .045 * k) * f * pow(max(.98 - hb * .085, .2), k) + center +
            n.xy * .01 * k;
        float w = pow(.75, k);
        acc += C(i, mir(f)).rgb * pal(k * .05 + h * .1) * w;
        ws += w;
    }
    acc /= ws;
    float shock = pow(max(sin(length(p - o) * (30.0 + b * 15.0) - time_f * 8.0), 0.0), 10.0);
    acc += pal(length(p - o) - time_f * .1) * shock * (.5 + a * 2.0);
    acc = mix(acc, 1.0 - acc, smoothstep(.91, 1.0, amp_peak));
    color = vec4(aces(acc * (.9 + amp_smooth * .3)), texture(samp, uv).a);
}
