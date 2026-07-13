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
    float f = 0.0, a = 0.5;
    for (int i = 0; i < 6; ++i) {
        f += a * noise21(p);
        p = mat2(0.8, -0.6, 0.6, 0.8) * p * 2.03 + 2.5;
        a *= 0.5;
    }
    return f;
}
vec2 mirrorUV(vec2 p) {
    return 1.0 - abs(mod(p, 2.0) - 1.0);
}
vec3 film(float t) {
    return 0.5 + 0.5 * cos(6.2831853 * (t + vec3(0.00, 0.29, 0.63)));
}
vec3 aces(vec3 x) {
    return clamp((x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14), 0.0, 1.0);
}
float opal(vec2 p) {
    float t = time_f;
    vec2 q = p + vec2(fbm(p * 2.0 + t * 0.06), fbm(p * 2.0 + 6.1 - t * 0.05)) * 0.28;
    float cloud = fbm(q * 4.0 + vec2(t * 0.08, -t * 0.07)), grain = fbm(q * 10.0 - t * 0.04);
    return cloud * 0.65 + grain * 0.22 + sin(q.x * 12.0 + q.y * 9.0 - t * 2.0 + cloud * 7.0) * 0.12;
}
vec3 normalAt(vec2 p, float e) {
    float h = opal(p);
    vec2 g = vec2(opal(p + vec2(e, 0)) - h, opal(p + vec2(0, e)) - h) / e;
    return normalize(vec3(-g * 0.19, 1));
}
void main(void) {
    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    float e = 2.0 / max(max(iResolution.x, iResolution.y), 320.0);
    float h = opal(p);
    vec3 n = normalAt(p, e);
    vec2 uv = mirrorUV(tc + n.xy * (0.025 + amp_mid * 0.018));
    float split = 0.002 + amp_high * 0.008;
    vec3 tex = vec3(texture(samp, mirrorUV(uv + n.xy * split)).r, texture(samp, uv).g,
                    texture(samp, mirrorUV(uv - n.xy * split)).b);
    float y = dot(tex, vec3(0.299, 0.587, 0.114));
    vec3 base = mix(vec3(y) * vec3(0.82, 0.88, 0.94), tex, 0.3);
    vec3 v = normalize(vec3(-p * 0.08, 1.6)), l0 = normalize(vec3(-0.6, 0.65, 0.55)),
         l1 = normalize(vec3(0.72, -0.28, 0.63));
    float nv = max(dot(n, v), 0.0);
    vec3 f0 = mix(vec3(0.52), base, 0.68);
    vec3 F = f0 + (1.0 - f0) * pow(1.0 - nv, 5.0);
    float s0 = pow(max(dot(n, normalize(v + l0)), 0.0), 135.0),
          s1 = pow(max(dot(n, normalize(v + l1)), 0.0), 30.0);
    vec3 irid = film(h * 1.6 + (1.0 - nv) * 1.8 + time_f * 0.018);
    vec3 col =
        base * (0.055 + 0.16 * max(dot(n, l0), 0.0)) +
        F * (irid * 1.05 + s0 * vec3(1.0, 0.9, 0.78) * 2.1 + s1 * vec3(0.35, 0.58, 1.0) * 0.85);
    float fleck = pow(fbm(p * 22.0 + time_f * 0.08), 14.0);
    col += film(h * 2.3 + time_f * 0.035) * fleck * (1.2 + amp_peak * 1.5);
    col = mix(col, col * irid, 0.18 + amp_smooth * 0.12);
    color = vec4(aces(col), texture(samp, uv).a);
}
