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
    return fract(sin(dot(p, vec2(123.4, 456.7))) * 43567.5453);
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
        p = mat2(0.8, -0.6, 0.6, 0.8) * p * 2.05 + 2.7;
        a *= 0.5;
    }
    return f;
}
vec2 mirrorUV(vec2 p) {
    return 1.0 - abs(mod(p, 2.0) - 1.0);
}
vec3 heatmap(float t) {
    t = clamp(t, 0.0, 1.0);
    return mix(mix(vec3(0.015, 0.002, 0.001), vec3(0.85, 0.035, 0.002), smoothstep(0.05, 0.5, t)),
               vec3(1.8, 0.72, 0.12), smoothstep(0.48, 1.0, t));
}
vec3 spectrum(float t) {
    return 0.5 + 0.5 * cos(6.2831853 * (t + vec3(0.0, 0.33, 0.67)));
}
vec3 aces(vec3 x) {
    return clamp((x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14), 0.0, 1.0);
}

float molten(vec2 p) {
    float t = time_f;
    vec2 q = p;
    q.x += sin(q.y * 4.0 - t * 0.8) * 0.3;
    q.y += sin(q.x * 3.0 + t * 0.6) * 0.24;
    float f0 = fbm(q * 2.5 + vec2(0, -t * 0.18));
    float f1 = fbm(q * 5.2 + vec2(t * 0.12, 0));
    float fold = abs(f0 - f1);
    return f0 * 0.55 + f1 * 0.22 - fold * 0.45 + sin(q.y * 13.0 - t * 3.0 + f0 * 8.0) * 0.1;
}
vec3 normalAt(vec2 p, float e) {
    float h = molten(p);
    vec2 g = vec2(molten(p + vec2(e, 0)) - h, molten(p + vec2(0, e)) - h) / e;
    return normalize(vec3(-g * 0.2, 1));
}
void main(void) {
    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    float e = 2.0 / max(max(iResolution.x, iResolution.y), 320.0);
    float h = molten(p);
    vec3 n = normalAt(p, e);
    vec2 uv = mirrorUV(tc + n.xy * (0.03 + amp_low * 0.025));
    float split = 0.003 + amp_high * 0.008;
    vec3 tex = vec3(texture(samp, mirrorUV(uv + n.xy * split)).r, texture(samp, uv).g,
                    texture(samp, mirrorUV(uv - n.xy * split)).b);
    float y = dot(tex, vec3(0.299, 0.587, 0.114));
    vec3 base = mix(vec3(y) * vec3(0.72, 0.65, 0.58), tex, 0.27);
    vec3 v = normalize(vec3(-p * 0.1, 1.6)), l0 = normalize(vec3(-0.6, 0.7, 0.55)),
         l1 = normalize(vec3(0.75, -0.3, 0.58));
    float nv = max(dot(n, v), 0.0);
    vec3 f0 = mix(vec3(0.56), base, 0.65);
    vec3 F = f0 + (1.0 - f0) * pow(1.0 - nv, 5.0);
    float s0 = pow(max(dot(n, normalize(v + l0)), 0.0), 130.0),
          s1 = pow(max(dot(n, normalize(v + l1)), 0.0), 28.0);
    vec3 env = spectrum(dot(reflect(-v, n), vec3(0.5, 0.25, 0.25)) * 0.28 + time_f * 0.018);
    vec3 col = base * (0.05 + 0.12 * max(dot(n, l0), 0.0)) +
               F * (env * 0.72 + s0 * vec3(1.0, 0.76, 0.5) * 2.4 + s1 * vec3(0.4, 0.55, 1.0) * 0.8);
    float heat = smoothstep(0.36, 0.63, fbm(p * 2.8 + vec2(0, -time_f * 0.14)));
    float vein = pow(1.0 - abs(sin(h * 17.0 + time_f * 1.5)), 18.0);
    col += heatmap(heat) * vein * (1.1 + amp_low * 1.5) + heatmap(heat) * heat * 0.18;
    col += spectrum(h * 0.2) * pow(max(n.z, 0.0), 10.0) * 0.08;
    color = vec4(aces(col * (1.0 + amp_peak * 0.25 + amp_smooth * 0.2)), texture(samp, uv).a);
}
