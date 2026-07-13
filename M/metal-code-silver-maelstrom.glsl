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

const float TAU = 6.28318530718;
float hash21(vec2 p) {
    return fract(sin(dot(p, vec2(37.1, 217.7))) * 43758.5453);
}
float noise21(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash21(i), hash21(i + vec2(1, 0)), f.x),
               mix(hash21(i + vec2(0, 1)), hash21(i + 1.0), f.x), f.y);
}
float fbm(vec2 p) {
    float f = 0.0, a = 0.5;
    for (int i = 0; i < 5; ++i) {
        f += a * noise21(p);
        p = mat2(0.6, -0.8, 0.8, 0.6) * p * 2.09 + 1.4;
        a *= 0.5;
    }
    return f;
}
vec2 mirrorUV(vec2 p) {
    return 1.0 - abs(mod(p, 2.0) - 1.0);
}
vec3 spectral(float t) {
    return 0.54 + 0.46 * cos(TAU * (t + vec3(0.0, 0.34, 0.67)));
}
vec3 tone(vec3 x) {
    return 1.0 - exp(-max(x, 0.0) * 1.1);
}
float maelstrom(vec2 p) {
    float r = length(p) + 0.025, a = atan(p.y, p.x);
    float twist = a + 1.15 / r + time_f * 0.8;
    float arms = sin(twist * 8.0 + r * 29.0 - time_f * 4.0);
    float counter = cos(twist * 14.0 - r * 41.0 + time_f * 6.0);
    return arms * 0.28 + counter * 0.13 +
           fbm(vec2(cos(twist), sin(twist)) * r * 5.0 + time_f * 0.08) * 0.58 +
           sin(r * 63.0 - time_f * 9.0) * 0.09;
}
vec3 normalAt(vec2 p, float e) {
    float h = maelstrom(p);
    vec2 g = vec2(maelstrom(p + vec2(e, 0)) - h, maelstrom(p + vec2(0, e)) - h) / e;
    return normalize(vec3(-g * 0.17, 1));
}
void main(void) {
    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    float e = 2.0 / max(max(iResolution.x, iResolution.y), 320.0);
    float h = maelstrom(p);
    vec3 n = normalAt(p, e);
    vec2 uv = mirrorUV(tc + n.xy * (0.03 + amp_low * 0.025));
    float split = 0.0025 + amp_high * 0.007;
    vec3 tex = vec3(texture(samp, mirrorUV(uv + n.xy * split)).r, texture(samp, uv).g,
                    texture(samp, mirrorUV(uv - n.xy * split)).b);
    float y = dot(tex, vec3(0.299, 0.587, 0.114));
    vec3 base = mix(vec3(y) * vec3(0.78, 0.86, 0.96), tex, 0.22);
    vec3 v = normalize(vec3(-p * 0.09, 1.55)), l0 = normalize(vec3(-0.68, 0.45, 0.7)),
         l1 = normalize(vec3(0.72, 0.38, 0.58));
    float nv = max(dot(n, v), 0.0);
    vec3 f0 = mix(vec3(0.68), base, 0.52);
    vec3 F = f0 + (1.0 - f0) * pow(1.0 - nv, 5.0);
    float s0 = pow(max(dot(n, normalize(v + l0)), 0.0), 175.0),
          s1 = pow(max(dot(n, normalize(v + l1)), 0.0), 42.0);
    vec3 env = spectral(dot(reflect(-v, n), vec3(0.4, 0.35, 0.25)) * 0.28 + time_f * 0.018);
    vec3 col = base * (0.035 + 0.13 * max(dot(n, l0), 0.0)) +
               F * (env * 0.9 + s0 * vec3(1.0, 0.9, 0.78) * 2.5 + s1 * vec3(0.3, 0.58, 1.15));
    float ring = pow(0.5 + 0.5 * sin(h * 16.0 - time_f * 3.0), 11.0);
    col += spectral(h * 0.3 + time_f * 0.025) * ring * (0.35 + amp_peak);
    col *= 0.88 + 0.18 * (1.0 - smoothstep(0.05, 0.65, length(p)));
    color = vec4(tone(col * (1.0 + amp_smooth * 0.3)), texture(samp, uv).a);
}
