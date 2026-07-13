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
        p = mat2(0.8, -0.6, 0.6, 0.8) * p * 2.07 + 1.9;
        a *= 0.5;
    }
    return f;
}
vec2 mirrorUV(vec2 p) {
    return 1.0 - abs(mod(p, 2.0) - 1.0);
}
vec3 thinFilm(float t) {
    return 0.5 + 0.5 * cos(6.2831853 * (t + vec3(0.00, 0.34, 0.68)));
}
vec3 aces(vec3 x) {
    return clamp((x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14), 0.0, 1.0);
}

float foundry(vec2 p) {
    float t = time_f;
    float flow = fbm(p * 2.2 + vec2(t * 0.12, -t * 0.2));
    vec2 q = p + vec2(fbm(p * 3.0 + t * 0.08), fbm(p * 3.0 + 8.7 - t * 0.09)) * 0.45;
    float hammer = fbm(q * 6.0);
    float channels = abs(sin(q.x * 8.0 + sin(q.y * 5.0 + t) * 2.0));
    return flow * 0.65 + hammer * 0.28 - channels * 0.20 + sin(length(p) * 24.0 - t * 4.0) * 0.08;
}
vec3 normalAt(vec2 p, float e) {
    float h = foundry(p);
    vec2 g = vec2(foundry(p + vec2(e, 0)) - h, foundry(p + vec2(0, e)) - h) / e;
    return normalize(vec3(-g * 0.2, 1));
}
vec3 lighting(vec3 base, vec3 n, vec2 p, float heat) {
    vec3 v = normalize(vec3(-p * 0.1, 1.6));
    vec3 l0 = normalize(vec3(-0.55, 0.72, 0.62)), l1 = normalize(vec3(0.8, -0.25, 0.55));
    float nv = max(dot(n, v), 0.0);
    vec3 f0 = mix(vec3(0.48), base, 0.78);
    vec3 F = f0 + (1.0 - f0) * pow(1.0 - nv, 5.0);
    float sp0 = pow(max(dot(n, normalize(v + l0)), 0.0), 110.0);
    float sp1 = pow(max(dot(n, normalize(v + l1)), 0.0), 32.0);
    vec3 refl =
        thinFilm(dot(reflect(-v, n), vec3(0.43, 0.37, 0.2)) * 0.35 + time_f * 0.018 + heat * 0.1);
    return base * (0.06 + 0.18 * max(dot(n, l0), 0.0)) +
           F * (refl * 0.9 + sp0 * vec3(1, 0.7, 0.35) * 2.8 + sp1 * vec3(0.25, 0.5, 1.2));
}
void main(void) {
    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    float e = 2.0 / max(max(iResolution.x, iResolution.y), 320.0);
    float h = foundry(p);
    vec3 n = normalAt(p, e);
    vec2 uv = mirrorUV(tc + n.xy * (0.028 + amp_low * 0.02));
    float ca = 0.003 + amp_high * 0.006;
    vec3 src = vec3(texture(samp, mirrorUV(uv + n.xy * ca)).r, texture(samp, uv).g,
                    texture(samp, mirrorUV(uv - n.xy * ca)).b);
    float y = dot(src, vec3(0.299, 0.587, 0.114));
    vec3 alloy = mix(vec3(y) * vec3(0.9, 0.72, 0.5), src, 0.32);
    float heat = smoothstep(0.42, 0.72, fbm(p * 2.4 + vec2(0, -time_f * 0.16)));
    vec3 col = lighting(alloy, n, p, heat);
    vec3 hot = mix(vec3(0.5, 0.015, 0.002), vec3(1.8, 0.65, 0.08), smoothstep(0.35, 0.8, heat));
    float crack = pow(1.0 - abs(sin(h * 10.0 + time_f)), 14.0);
    col += hot * heat * (0.25 + 0.65 * amp_low) +
           thinFilm(h * 0.35 + time_f * 0.025) * crack * (0.2 + amp_peak);
    color = vec4(aces(col * (1.0 + amp_smooth * 0.25)), texture(samp, uv).a);
}
