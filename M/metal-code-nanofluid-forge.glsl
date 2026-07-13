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
vec3 cells(vec2 p) {
    vec2 n = floor(p), f = fract(p);
    float d1 = 9.0, d2 = 9.0, id = 0.0;
    for (int y = -1; y <= 1; ++y)
        for (int x = -1; x <= 1; ++x) {
            vec2 g = vec2(x, y), o = 0.5 + 0.42 * sin(6.2831 * hash22(n + g) + time_f * 0.55);
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
vec3 alloyColor(float t) {
    return 0.52 + 0.48 * cos(6.2831853 * (t + vec3(0.04, 0.37, 0.69)));
}
vec3 heatmap(float t) {
    return mix(vec3(0.08, 0.005, 0.002), vec3(1.7, 0.48, 0.035), smoothstep(0.15, 0.78, t));
}
vec3 tone(vec3 x) {
    return 1.0 - exp(-max(x, 0.0) * 1.08);
}
float nano(vec2 p) {
    p += vec2(sin(p.y * 4.0 - time_f), cos(p.x * 3.0 + time_f * 0.8)) * 0.13;
    vec3 a = cells(p * (7.0 + amp_low * 2.0));
    vec3 b = cells((p + 3.7) * (13.0 + amp_mid * 3.0));
    float membrane = exp(-a.y * 15.0), micro = exp(-b.y * 21.0);
    return (1.0 - a.x) * 0.36 - membrane * 0.24 + micro * 0.12 +
           sin(a.x * 31.0 - time_f * 6.0) * 0.08 + a.z * 0.05;
}
vec3 normalAt(vec2 p, float e) {
    float h = nano(p);
    vec2 g = vec2(nano(p + vec2(e, 0)) - h, nano(p + vec2(0, e)) - h) / e;
    return normalize(vec3(-g * 0.17, 1));
}
void main(void) {
    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    float e = 2.0 / max(max(iResolution.x, iResolution.y), 320.0);
    vec3 cell = cells((p + vec2(sin(p.y * 4.0 - time_f), cos(p.x * 3.0 + time_f * 0.8)) * 0.13) *
                      (7.0 + amp_low * 2.0));
    float h = nano(p);
    vec3 n = normalAt(p, e);
    vec2 uv = mirrorUV(tc + n.xy * (0.026 + amp_mid * 0.02));
    float split = 0.0025 + amp_high * 0.008;
    vec3 tex = vec3(texture(samp, mirrorUV(uv + n.xy * split)).r, texture(samp, uv).g,
                    texture(samp, mirrorUV(uv - n.xy * split)).b);
    float y = dot(tex, vec3(0.299, 0.587, 0.114));
    vec3 base = mix(vec3(y) * alloyColor(cell.z * 0.22), tex, 0.3);
    vec3 v = normalize(vec3(-p * 0.08, 1.55)), l0 = normalize(vec3(-0.62, 0.62, 0.57)),
         l1 = normalize(vec3(0.76, -0.25, 0.6));
    float nv = max(dot(n, v), 0.0);
    vec3 f0 = mix(vec3(0.58), base, 0.64);
    vec3 F = f0 + (1.0 - f0) * pow(1.0 - nv, 5.0);
    float s0 = pow(max(dot(n, normalize(v + l0)), 0.0), 155.0),
          s1 = pow(max(dot(n, normalize(v + l1)), 0.0), 34.0);
    vec3 env =
        alloyColor(dot(reflect(-v, n), vec3(0.45, 0.3, 0.25)) * 0.3 + time_f * 0.02 + cell.z * 0.1);
    vec3 col = base * (0.045 + 0.14 * max(dot(n, l0), 0.0)) +
               F * (env * 0.82 + s0 * vec3(1.0, 0.82, 0.65) * 2.4 + s1 * vec3(0.28, 0.55, 1.1));
    float edge = exp(-cell.y * 23.0);
    float hot = smoothstep(0.2, 0.58, edge * (0.7 + 0.3 * sin(time_f * 2.0 + cell.z * 8.0)));
    col += alloyColor(cell.z + time_f * 0.03) * edge * 0.5 +
           heatmap(hot) * hot * (0.65 + amp_peak * 1.5);
    color = vec4(tone(col * (1.0 + amp_smooth * 0.25)), texture(samp, uv).a);
}
