#version 330 core
// Prismatic Caustic Whirlpool: liquid-metal normals, refractive caustics, and spiral time echoes.
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
    return .5 + .5 * cos(TAU * (x + vec3(.0, .28, .64)));
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
    float r = length(q) + .001, a = atan(q.y, q.x);
    float vortex = sin(a * (4.0 + floor(amp_high * 4.0)) - log(r) * 9.0 - time_f * (3.0 + b * 3.0));
    float rings = sin(r * (28.0 + b * 18.0) - time_f * 6.0);
    float caust = abs(sin((q.x + sin(q.y * 5.0)) * 15.0 + time_f * 2.0)) *
                  abs(cos((q.y - cos(q.x * 4.0)) * 13.0 - time_f));
    return vortex * .18 + rings * .12 + (caust - .25) * .2 + m * .05 * sin(a * 12.0);
}
void main() {
    vec2 res = max(iResolution, vec2(1)), mu = iMouse.xy / res;
    float ar = res.x / res.y;
    vec2 p = (tc - .5) * vec2(ar, 1), o = (iMouse.z > 0.0) ? (mu - .5) * vec2(ar, 1) : vec2(0);
    float b = texture(spectrum0, .03).r, m = texture(spectrum0, .22).r,
          t = texture(spectrum0, .58).r, a = texture(spectrum0, .8).r;
    float e = 2.0 / max(max(res.x, res.y), 360.0), h = H(p, o, b, m);
    vec2 g = vec2(H(p + vec2(e, 0), o, b, m) - h, H(p + vec2(0, e), o, b, m) - h) / e;
    vec3 n = normalize(vec3(-g * .22, 1));
    vec2 q = p - o;
    float rr = length(q);
    vec2 swirl = R((.18 + b * .25) * exp(-rr * 1.4)) * q + o;
    vec2 base = swirl / vec2(ar, 1) + .5 + n.xy * (.02 + amp_low * .04), uv = mir(base);
    float split = .006 + t * .02;
    vec3 tex = vec3(texture(samp, mir(uv + n.xy * split)).r, texture(samp, uv).g,
                    texture(samp, mir(uv - n.xy * split)).b);
    vec3 v = normalize(vec3(-p * .1, 1.7));
    float fr = pow(1.0 - max(dot(n, v), 0.0), 4.0);
    float caust = pow(max(dot(n, normalize(vec3(.5, .7, 1))), 0.0), 30.0);
    vec3 cur = mix(tex, pal(h * 1.7 + rr - time_f * .08) * dot(tex, vec3(.333)) * 1.5, .5) +
               pal(n.x - n.y + time_f * .04) * (fr * .8 + caust * 2.0);
    vec3 acc = cur;
    float ws = 1.0;
    vec2 center = (iMouse.z > 0.0) ? mu : vec2(.5);
    for (int i = 0; i < 8; i++) {
        float k = float(i + 1), hb = S(i, .03), hm = S(i, .22), ht = S(i, .58);
        float ang = (.025 + ht * .14) * k + sin(time_f * .2 + k) * .01;
        vec2 f = R(ang) * (tc - center) * pow(max(.97 - hb * .1, .2), k) + center;
        f += n.xy * k * (.006 + hm * .012);
        float w = pow(.76, k);
        acc += C(i, mir(f)).rgb * pal(h * .2 + k * .045) * w;
        ws += w;
    }
    acc /= ws;
    acc += pal(rr * 1.5 - time_f * .15) * pow(max(sin(h * 22.0), 0.0), 7.0) * (1.0 + a * 2.0);
    acc = mix(acc, 1.0 - acc, smoothstep(.91, 1.0, amp_peak));
    color = vec4(aces(acc * (.9 + amp_smooth * .3)), texture(samp, uv).a);
}
