#version 330 core
// Mercury Kaleido Bloom: folded ripple petals with mirrored chrome feedback.
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
    return .52 + .48 * cos(TAU * (x + vec3(.08, .37, .72)));
}
vec3 tone(vec3 x) {
    return x / (1.0 + x);
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
vec2 kaleido(vec2 p, float sides) {
    float a = atan(p.y, p.x), r = length(p), w = TAU / sides;
    a = abs(mod(a + w * .5, w) - w * .5);
    return vec2(cos(a), sin(a)) * r;
}
float H(vec2 p, vec2 o, float b, float m) {
    vec2 q = p - o;
    float r = length(q), a = atan(q.y, q.x);
    float petals = cos(a * (6.0 + floor(amp_high * 6.0)) - r * (14.0 + b * 8.0) + time_f * 2.5);
    float rip = sin(r * (24.0 + b * 16.0) - time_f * 5.5);
    float cells = sin(q.x * 18.0 + sin(q.y * 9.0 + time_f)) * cos(q.y * 16.0 - time_f * .7);
    return petals * .18 + rip * .13 + cells * .08 * (.5 + m);
}
void main() {
    vec2 res = max(iResolution, vec2(1)), mu = iMouse.xy / res;
    float ar = res.x / res.y;
    float b = texture(spectrum0, .03).r, m = texture(spectrum0, .22).r,
          t = texture(spectrum0, .58).r;
    vec2 p = (tc - .5) * vec2(ar, 1), o = (iMouse.z > 0.0) ? (mu - .5) * vec2(ar, 1) : vec2(0);
    float sides = 6.0 + floor(t * 8.0);
    vec2 kp = kaleido(p - o, sides) + o;
    float e = 2.0 / max(max(res.x, res.y), 320.0), h = H(kp, o, b, m);
    vec2 g = vec2(H(kp + vec2(e, 0), o, b, m) - h, H(kp + vec2(0, e), o, b, m) - h) / e;
    vec3 n = normalize(vec3(-g * .28, 1));
    vec2 uv = mir(kp / vec2(ar, 1) + .5 + n.xy * (.025 + amp_low * .04));
    float d = .005 + t * .016;
    vec3 tex = vec3(texture(samp, mir(uv + n.xy * d)).r, texture(samp, uv).g,
                    texture(samp, mir(uv - n.xy * d)).b);
    vec3 v = normalize(vec3(-p * .13, 1.8));
    float fres = pow(1.0 - max(dot(n, v), 0.0), 5.0), shine = pow(max(n.z, 0.0), 35.0);
    vec3 cur = mix(tex * pal(h + b), pal(h * 2.0 + time_f * .07) * dot(tex, vec3(.333)), .48) +
               pal(n.x * .3 + time_f * .03) * (fres + shine);
    vec3 acc = cur;
    float ws = 1.0;
    vec2 center = (iMouse.z > 0.0) ? mu : vec2(.5);
    for (int i = 0; i < 8; i++) {
        float k = float(i + 1), hb = S(i, .03), ht = S(i, .58);
        vec2 f = tc - center;
        f = kaleido((R((.015 + ht * .08) * k) * f) * pow(max(.972 - hb * .08, .25), k), sides) +
            center;
        float w = pow(.73, k);
        acc += C(i, mir(f)).rgb * pal(k * .06 + h * .18) * w;
        ws += w;
    }
    acc /= ws;
    float edge = pow(max(sin(h * 20.0 - time_f * 2.0), 0.0), 8.0);
    acc += pal(h + time_f * .12) * edge * (.7 + amp_peak * 1.5);
    acc = mix(acc, 1.0 - acc, smoothstep(.9, 1.0, amp_peak));
    color = vec4(tone(max(acc, 0.0) * (1.1 + amp_smooth * .25)), texture(samp, uv).a);
}
