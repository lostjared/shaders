#version 330 core

in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform float amp_low;
uniform float amp_mid;
uniform float amp_high;

float hash21(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
float noise21(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash21(i), hash21(i + vec2(1, 0)), f.x),
               mix(hash21(i + vec2(0, 1)), hash21(i + 1.0), f.x), f.y);
}
float fbm(vec2 p) {
    float s = 0.0, a = 0.5;
    for (int i = 0; i < 6; ++i) {
        s += a * noise21(p);
        p = mat2(0.8, -0.6, 0.6, 0.8) * p * 2.06 + 2.1;
        a *= 0.5;
    }
    return s;
}
vec2 mirrorUV(vec2 p) {
    return 1.0 - abs(mod(p, 2.0) - 1.0);
}
vec3 plasma(float t) {
    return 0.52 + 0.48 * cos(6.2831853 * (t + vec3(0.08, 0.38, 0.7)));
}
vec3 aces(vec3 x) {
    return clamp((x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14), 0.0, 1.0);
}
float alloy(vec2 p) {
    float t = time_f;
    vec2 q = p + vec2(fbm(p * 2.5 + t * 0.1), fbm(p * 2.5 + 7.3 - t * 0.08)) * 0.38;
    float liquid = fbm(q * 4.0 + vec2(0, -t * 0.2));
    float arc = sin(q.x * 18.0 + sin(q.y * 7.0 - t * 2.0) * 4.0 + t * 4.0);
    return liquid * 0.62 + arc * 0.16 + sin(length(q) * 37.0 - t * 7.0 + liquid * 6.0) * 0.11;
}
vec3 normalAt(vec2 p, float e) {
    float h = alloy(p);
    vec2 g = vec2(alloy(p + vec2(e, 0)) - h, alloy(p + vec2(0, e)) - h) / e;
    return normalize(vec3(-g * 0.18, 1));
}
void main(void) {
    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    float e = 2.0 / max(max(iResolution.x, iResolution.y), 320.0);
    float h = alloy(p);
    vec3 n = normalAt(p, e);
    vec2 uv = mirrorUV(tc + n.xy * (0.028 + amp_mid * 0.02));
    float split = 0.003 + amp_high * 0.009;
    vec3 tex = vec3(texture(samp, mirrorUV(uv + n.xy * split)).r, texture(samp, uv).g,
                    texture(samp, mirrorUV(uv - n.xy * split)).b);
    float y = dot(tex, vec3(0.299, 0.587, 0.114));
    vec3 base = mix(vec3(y) * vec3(0.68, 0.78, 0.95), tex, 0.28);
    vec3 v = normalize(vec3(-p * 0.1, 1.55)), l0 = normalize(vec3(-0.55, 0.7, 0.58)),
         l1 = normalize(vec3(0.78, -0.2, 0.6));
    float nv = max(dot(n, v), 0.0);
    vec3 f0 = mix(vec3(0.6), base, 0.6);
    vec3 F = f0 + (1.0 - f0) * pow(1.0 - nv, 5.0);
    float s0 = pow(max(dot(n, normalize(v + l0)), 0.0), 140.0),
          s1 = pow(max(dot(n, normalize(v + l1)), 0.0), 32.0);
    vec3 env = plasma(dot(reflect(-v, n), vec3(0.45, 0.3, 0.25)) * 0.3 + time_f * 0.025);
    vec3 col = base * (0.045 + 0.14 * max(dot(n, l0), 0.0)) +
               F * (env * 0.8 + s0 * vec3(1.0, 0.85, 0.75) * 2.3 + s1 * vec3(0.25, 0.55, 1.2));
    float arc = pow(abs(sin(h * 19.0 + time_f * 4.0)), 22.0);
    float corona = pow(0.5 + 0.5 * sin(length(p) * 55.0 - time_f * 9.0 + h * 5.0), 12.0);
    col += plasma(h * 0.4 + time_f * 0.04) * (arc * 0.8 + corona * 0.35) * (1.0 + amp_peak * 1.3);
    color = vec4(aces(col * (1.0 + amp_smooth * 0.28)), texture(samp, uv).a);
}
