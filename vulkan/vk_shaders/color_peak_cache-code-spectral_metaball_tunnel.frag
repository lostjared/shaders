#version 450

layout(set = 0, binding = 1, std140) uniform SpriteExtended {
    vec4 mouse;
    vec4 u0;
    vec4 u1;
    vec4 u2;
    vec4 u3;
    vec4 custom_uniforms[16];
    vec4 audio_bands;
    vec4 audio_history;
} ext;
#define amp_high ext.audio_bands.z
#define amp_low ext.audio_bands.x
#define amp_mid ext.audio_bands.y
#define amp_peak ext.u2.w
#define amp_smooth ext.u3.w
#define history_head int(ext.u3.x)
#define iMouse ext.mouse
#define iResolution ext.u0.zw
#define spectrum_history_head int(ext.audio_history.x)
#define spectrum_history_size int(ext.audio_history.y)
#define time_f ext.u2.y

// Spectral Metaball Tunnel: lava-lamp geometry, acid interference, and corkscrew cache recursion.
layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;
layout(set = 0, binding = 2) uniform sampler2DArray history;

#ifndef SIZE
#define SIZE 8
#endif
#ifndef CACHE_HISTORY_LAYER
#define CACHE_HISTORY_LAYER(index) ((history_head + (index)) % SIZE)
#endif
layout(set = 0, binding = 3) uniform sampler1D spectrum0;
layout(set = 0, binding = 4) uniform sampler1DArray spectrum_history;


#ifndef SPECTRUM_HISTORY_LAYER
#define SPECTRUM_HISTORY_LAYER(index) ((spectrum_history_head - ((index) % max(spectrum_history_size, 1)) + max(spectrum_history_size, 1)) % max(spectrum_history_size, 1))
#endif



const float TAU = 6.28318530718;
vec2 mir(vec2 u) {
    return 1.0 - abs(mod(u, 2.0) - 1.0);
}
mat2 R(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c);
}
vec3 pal(float x) {
    return .54 + .46 * cos(TAU * (x + vec3(.13, .39, .73)));
}
vec3 tone(vec3 x) {
    return clamp(x / (.75 + x), 0.0, 1.0);
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
float H(vec2 p, vec2 o, float b, float m) {
    vec2 q = p - o;
    float pot = 0.0;
    for (int i = 0; i < 5; i++) {
        float k = float(i), ph = k * 1.257;
        vec2 c = vec2(sin(time_f * (.24 + k * .025) + ph) * (.12 + k * .025),
                      cos(time_f * (.31 - k * .018) + ph) * (.28 - k * .02));
        float d = dot(q - c, q - c);
        pot += .018 / (d + .018);
    }
    float r = length(q), a = atan(q.y, q.x);
    float tunnel = sin(log(r + .08) * 12.0 - a * (3.0 + floor(amp_high * 4.0)) + time_f * 4.0);
    return (pot - .5) * .25 + tunnel * .11 + sin(r * (23.0 + b * 15.0) - time_f * 5.0) * .07 * m;
}
void main() {
    vec2 res = max(iResolution, vec2(1)), mu = iMouse.xy / res;
    float ar = res.x / res.y, b = texture(spectrum0, .03).r, m = texture(spectrum0, .22).r,
          t = texture(spectrum0, .58).r, a = texture(spectrum0, .8).r;
    vec2 p = (tc - .5) * vec2(ar, 1), o = (iMouse.z > 0.0) ? (mu - .5) * vec2(ar, 1) : vec2(0);
    float e = 2.0 / max(max(res.x, res.y), 360.0), h = H(p, o, b, m);
    vec2 g = vec2(H(p + vec2(e, 0), o, b, m) - h, H(p + vec2(0, e), o, b, m) - h) / e;
    vec3 n = normalize(vec3(-g * .2, 1));
    vec2 q = p - o;
    float rr = length(q);
    q = R((.22 + b * .3) * exp(-rr * 1.2)) * q + o;
    vec2 uv = mir(q / vec2(ar, 1) + .5 + n.xy * (.028 + amp_low * .05));
    float d = .005 + t * .019;
    vec3 tex = vec3(texture(samp, mir(uv + n.xy * d)).r, texture(samp, uv).g,
                    texture(samp, mir(uv - n.xy * d)).b);
    vec3 v = normalize(vec3(-p * .1, 1.7)), l = normalize(vec3(-.5, .7, .8));
    float fr = pow(1.0 - max(dot(n, v), 0.0), 5.0),
          sp = pow(max(dot(n, normalize(v + l)), 0.0), 52.0);
    vec3 cur = mix(tex, pal(h * 1.5 + b + time_f * .04) * (.32 + dot(tex, vec3(.333))), .55) *
                   (.2 + .5 * max(dot(n, l), 0.0)) +
               pal(h + n.x * .2) * (fr * .8 + sp * 2.0);
    vec3 acc = cur;
    float ws = 1.0;
    vec2 center = (iMouse.z > 0.0) ? mu : vec2(.5);
    for (int i = 0; i < 8; i++) {
        float k = float(i + 1), hb = S(i, .03), hm = S(i, .22), ht = S(i, .58);
        float z = pow(max(.96 - hb * .1, .2), k);
        vec2 f =
            R((.035 + ht * .13) * k) * (tc - center) * z + center + n.xy * (.007 + hm * .014) * k;
        float w = pow(.77, k);
        acc += C(i, mir(f)).rgb * pal(k * .065 + h * .1) * w;
        ws += w;
    }
    acc /= ws;
    acc += pal(h + time_f * .1) * pow(max(sin(h * 23.0 - time_f * 2.0), 0.0), 7.0) * (.7 + a * 1.7);
    acc = mix(acc, 1.0 - acc, smoothstep(.9, 1.0, amp_peak));
    color = vec4(tone(acc * (1.0 + amp_smooth * .25)), texture(samp, uv).a);
}
