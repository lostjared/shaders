#version 330 core
// Crystalline Sonar Garden: hexagonal mineral growths bloom where concentric audio scans collide.
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
    return .5 + .5 * cos(TAU * (x + vec3(.07, .35, .66)));
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
vec2 hex(vec2 p) {
    vec2 s = vec2(1.0, 1.732), a = mod(p, s) - s * .5, b = mod(p - s * .5, s) - s * .5;
    return dot(a, a) < dot(b, b) ? a : b;
}
float H(vec2 p, vec2 o, float b, float m) {
    vec2 q = p - o, hx = hex((p + vec2(0, time_f * .025)) * 8.0);
    float crystal = pow(max(1.0 - length(hx) * 1.35, 0.0), 4.0);
    float facet = cos(atan(hx.y, hx.x) * 6.0) * .5 + .5;
    float r = length(q);
    vec2 s = vec2(sin(time_f * .3), cos(time_f * .37)) * .2;
    float sonar = sin(r * (27.0 + b * 18.0) - time_f * 7.0) +
                  sin(length(q - s) * (22.0 + m * 14.0) - time_f * 5.0);
    return crystal * (.18 + facet * .15) + sonar * .085;
}
void main() {
    vec2 res = max(iResolution, vec2(1)), mu = iMouse.xy / res;
    float ar = res.x / res.y, b = texture(spectrum0, .03).r, m = texture(spectrum0, .22).r,
          t = texture(spectrum0, .58).r, a = texture(spectrum0, .8).r;
    vec2 p = (tc - .5) * vec2(ar, 1), o = (iMouse.z > 0.0) ? (mu - .5) * vec2(ar, 1) : vec2(0);
    float e = 2.0 / max(max(res.x, res.y), 360.0), h = H(p, o, b, m);
    vec2 g = vec2(H(p + vec2(e, 0), o, b, m) - h, H(p + vec2(0, e), o, b, m) - h) / e;
    vec3 n = normalize(vec3(-g * .27, 1));
    vec2 hx = hex((p + vec2(0, time_f * .025)) * 8.0),
         uv = mir(tc + n.xy * (.026 + amp_low * .05) + hx * .008);
    float d = .006 + t * .019;
    vec3 tex = vec3(texture(samp, mir(uv + n.xy * d)).r, texture(samp, uv).g,
                    texture(samp, mir(uv - n.xy * d)).b);
    vec3 v = normalize(vec3(-p * .13, 1.8)), l0 = normalize(vec3(-.6, .7, .8)),
         l1 = normalize(vec3(.7, -.2, .7));
    float s0 = pow(max(dot(n, normalize(v + l0)), 0.0), 90.0),
          s1 = pow(max(dot(n, normalize(v + l1)), 0.0), 45.0),
          fr = pow(1.0 - max(dot(n, v), 0.0), 5.0);
    vec3 cur = mix(tex, pal(h * 2.2 + atan(hx.y, hx.x) / TAU) * dot(tex, vec3(.333)) * 1.45, .53);
    cur *= .18 + .48 * max(dot(n, l0), 0.0);
    cur += pal(n.x - n.y + time_f * .04) * (s0 * 2.4 + s1 * 1.4 + fr * .7);
    vec3 acc = cur;
    float ws = 1.0;
    vec2 center = (iMouse.z > 0.0) ? mu : vec2(.5);
    for (int i = 0; i < 8; i++) {
        float k = float(i + 1), hb = S(i, .03), hm = S(i, .22), ht = S(i, .58);
        vec2 f = tc - center;
        f = R((ht - .18) * .045 * k) * f * pow(max(.975 - hb * .085, .25), k) + center +
            normalize(hx + vec2(.001)) * (.003 + hm * .009) * k;
        float w = pow(.74, k);
        acc += C(i, mir(f)).rgb * pal(k * .05 + h * .15) * w;
        ws += w;
    }
    acc /= ws;
    float scan = pow(max(sin(length(p - o) * (31.0 + b * 15.0) - time_f * 8.0), 0.0), 11.0);
    acc += pal(length(p - o) - time_f * .12) * scan * (.6 + a * 2.2);
    acc = mix(acc, 1.0 - acc, smoothstep(.91, 1.0, amp_peak));
    color = vec4(aces(acc * (.92 + amp_smooth * .3)), texture(samp, uv).a);
}
