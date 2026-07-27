#version 330 core
// Temporal Mosaic Fracture: Voronoi-like chrome plates split the ripple field into delayed time
// shards.
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
    return .52 + .48 * cos(TAU * (x + vec3(.05, .38, .71)));
}
vec3 tone(vec3 x) {
    return clamp(x / (.8 + x), 0.0, 1.0);
}
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(41.3, 289.1))) * 43758.54);
}
vec2 cell(vec2 p) {
    vec2 i = floor(p), f = fract(p), best = vec2(0);
    float md = 9.0;
    for (int y = -1; y <= 1; y++)
        for (int x = -1; x <= 1; x++) {
            vec2 g = vec2(x, y), r = g + vec2(hash(i + g), hash(i + g + 17.3)) * .72 - f;
            float d = dot(r, r);
            if (d < md) {
                md = d;
                best = r;
            }
        }
    return best;
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
    vec2 q = p - o, c = cell((p + vec2(time_f * .025, 0)) * 7.0);
    float edge = 1.0 - smoothstep(.02, .19, length(c));
    float r = length(q);
    float rip = sin(r * (24.0 + b * 17.0) - time_f * 5.5);
    float shard = sin(atan(c.y, c.x) * 6.0 + length(c) * 30.0 + time_f * 2.0);
    return edge * .27 + rip * .12 + shard * .09 + m * .04 * sin(p.x * 24.0);
}
void main() {
    vec2 res = max(iResolution, vec2(1)), mu = iMouse.xy / res;
    float ar = res.x / res.y, b = texture(spectrum0, .03).r, m = texture(spectrum0, .22).r,
          t = texture(spectrum0, .58).r, a = texture(spectrum0, .8).r;
    vec2 p = (tc - .5) * vec2(ar, 1), o = (iMouse.z > 0.0) ? (mu - .5) * vec2(ar, 1) : vec2(0);
    float e = 2.0 / max(max(res.x, res.y), 340.0), h = H(p, o, b, m);
    vec2 g = vec2(H(p + vec2(e, 0), o, b, m) - h, H(p + vec2(0, e), o, b, m) - h) / e;
    vec3 n = normalize(vec3(-g * .26, 1));
    vec2 cv = cell((p + vec2(time_f * .025, 0)) * 7.0),
         uv = mir(tc + n.xy * (.025 + amp_low * .045) + cv * .018);
    float d = .005 + t * .018;
    vec3 tex = vec3(texture(samp, mir(uv + n.xy * d)).r, texture(samp, uv).g,
                    texture(samp, mir(uv - n.xy * d)).b);
    vec3 v = normalize(vec3(-p * .12, 1.8));
    float fr = pow(1.0 - max(dot(n, v), 0.0), 5.0), sp = pow(max(n.z, 0.0), 55.0);
    vec3 cur = mix(tex, pal(h * 2.0 + hash(floor(p * 7.0))) * dot(tex, vec3(.333)) * 1.3, .55) +
               pal(n.x - n.y + time_f * .04) * (fr * .8 + sp);
    vec3 acc = cur;
    float ws = 1.0;
    vec2 center = (iMouse.z > 0.0) ? mu : vec2(.5);
    for (int i = 0; i < 8; i++) {
        float k = float(i + 1), hb = S(i, .03), hm = S(i, .22), ht = S(i, .58);
        vec2 f = tc - center;
        vec2 tile = floor(tc * (7.0 + floor(t * 5.0)));
        float dir = hash(tile + k) - .5;
        f = R(dir * (.06 + ht * .08) * k) * f * pow(max(.98 - hb * .08, .25), k) + center +
            cv * hm * .025 * k;
        float w = pow(.73, k);
        acc += C(i, mir(f)).rgb * pal(hash(tile) + k * .04) * w;
        ws += w;
    }
    acc /= ws;
    acc += pal(h + time_f * .1) * pow(max(sin(h * 25.0), 0.0), 9.0) * (.5 + a * 1.8);
    acc = mix(acc, 1.0 - acc, smoothstep(.9, 1.0, amp_peak));
    color = vec4(tone(acc * (1.05 + amp_smooth * .25)), texture(samp, uv).a);
}
