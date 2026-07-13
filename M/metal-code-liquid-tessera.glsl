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
vec2 hash22(vec2 p) {
    return fract(sin(vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)))) * 43758.5453);
}
vec3 voronoi(vec2 p) {
    vec2 n = floor(p), f = fract(p);
    float d1 = 9.0, d2 = 9.0, id = 0.0;
    for (int y = -1; y <= 1; ++y)
        for (int x = -1; x <= 1; ++x) {
            vec2 g = vec2(x, y), o = 0.5 + 0.38 * sin(6.2831 * hash22(n + g) + time_f * 0.35);
            float d = length(g + o - f);
            if (d < d1) {
                d2 = d1;
                d1 = d;
                id = hash21(n + g);
            } else if (d < d2)
                d2 = d;
        }
    return vec3(d1, d2 - d1, id);
}
vec2 mirrorUV(vec2 p) {
    return 1.0 - abs(mod(p, 2.0) - 1.0);
}
vec3 spectral(float t) {
    return 0.52 + 0.48 * cos(6.2831853 * (t + vec3(0.0, 0.3, 0.66)));
}
vec3 tone(vec3 x) {
    return 1.0 - exp(-max(x, 0.0) * 1.12);
}

float tiles(vec2 p) {
    p += vec2(sin(p.y * 3.0 + time_f * 0.7), cos(p.x * 3.0 - time_f * 0.6)) * 0.16;
    vec3 v = voronoi(p * (5.0 + amp_low * 2.0));
    float edge = exp(-v.y * 12.0);
    float bowl = 1.0 - smoothstep(0.05, 0.75, v.x);
    return bowl * 0.45 - edge * 0.24 + sin(v.x * 22.0 - time_f * 4.0) * 0.1 + v.z * 0.08;
}
vec3 normalAt(vec2 p, float e) {
    float h = tiles(p);
    vec2 g = vec2(tiles(p + vec2(e, 0)) - h, tiles(p + vec2(0, e)) - h) / e;
    return normalize(vec3(-g * 0.18, 1));
}
void main(void) {
    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    float e = 2.0 / max(max(iResolution.x, iResolution.y), 320.0);
    vec3 cell =
        voronoi((p + vec2(sin(p.y * 3.0 + time_f * 0.7), cos(p.x * 3.0 - time_f * 0.6)) * 0.16) *
                (5.0 + amp_low * 2.0));
    float h = tiles(p);
    vec3 n = normalAt(p, e);
    vec2 uv = mirrorUV(tc + n.xy * (0.027 + amp_mid * 0.018));
    float split = 0.002 + amp_high * 0.007;
    vec3 tex = vec3(texture(samp, mirrorUV(uv + n.xy * split)).r, texture(samp, uv).g,
                    texture(samp, mirrorUV(uv - n.xy * split)).b);
    float y = dot(tex, vec3(0.299, 0.587, 0.114));
    vec3 base = mix(vec3(y) * spectral(cell.z * 0.35), tex, 0.34);
    vec3 v = normalize(vec3(-p * 0.08, 1.5));
    vec3 l0 = normalize(vec3(-0.65, 0.55, 0.68)), l1 = normalize(vec3(0.75, -0.25, 0.61));
    float nv = max(dot(n, v), 0.0);
    vec3 f0 = mix(vec3(0.58), base, 0.62);
    vec3 F = f0 + (1.0 - f0) * pow(1.0 - nv, 5.0);
    float s0 = pow(max(dot(n, normalize(v + l0)), 0.0), 150.0),
          s1 = pow(max(dot(n, normalize(v + l1)), 0.0), 35.0);
    vec3 env = spectral(dot(reflect(-v, n), vec3(0.42, 0.3, 0.28)) * 0.3 + time_f * 0.02 + cell.z);
    vec3 col = base * (0.05 + 0.15 * max(dot(n, l0), 0.0)) +
               F * (env * 0.85 + s0 * vec3(1.0, 0.85, 0.7) * 2.2 + s1 * vec3(0.3, 0.55, 1.0) * 0.9);
    float edge = exp(-cell.y * 20.0);
    col += spectral(cell.z + time_f * 0.03) * edge * (0.55 + amp_peak * 1.4);
    col *= 0.82 + 0.25 * cell.x;
    color = vec4(tone(col * (1.0 + amp_smooth * 0.25)), texture(samp, uv).a);
}
