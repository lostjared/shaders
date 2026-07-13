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
    return fract(sin(dot(p, vec2(41.7, 289.1))) * 45758.5453);
}
float noise21(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash21(i), hash21(i + vec2(1, 0)), f.x),
               mix(hash21(i + vec2(0, 1)), hash21(i + 1.0), f.x), f.y);
}
float fbm(vec2 p) {
    float s = 0.0, a = 0.5;
    mat2 m = mat2(0.6, -0.8, 0.8, 0.6);
    for (int i = 0; i < 6; ++i) {
        s += a * noise21(p);
        p = m * p * 2.04 + 2.3;
        a *= 0.5;
    }
    return s;
}
vec2 mirrorUV(vec2 p) {
    return 1.0 - abs(mod(p, 2.0) - 1.0);
}
vec3 film(float x) {
    return 0.52 + 0.48 * cos(6.2831853 * (x + vec3(0.02, 0.35, 0.68)));
}
vec3 tonemap(vec3 x) {
    x = max(x, 0.0);
    return 1.0 - exp(-x * (1.05 + 0.18 * x));
}

float tideHeight(vec2 p) {
    float t = time_f;
    vec2 q = p;
    q.x += sin(q.y * 3.5 - t * 0.7) * 0.38;
    q.y += sin(q.x * 4.2 + t * 0.5) * 0.31;
    float broad = sin(q.x * 7.0 + q.y * 5.0 - t * 2.2);
    float cross = cos(q.x * 13.0 - q.y * 9.0 + t * 3.1);
    float micro = fbm(q * 4.0 + vec2(t * 0.16, -t * 0.12));
    return broad * 0.34 + cross * 0.18 + micro * 0.78;
}
vec3 getNormal(vec2 p, float e) {
    float h = tideHeight(p);
    vec2 d = vec2(tideHeight(p + vec2(e, 0)) - h, tideHeight(p + vec2(0, e)) - h) / e;
    return normalize(vec3(-d * 0.16, 1.0));
}
float ggx(float nh, float rough) {
    float a = rough * rough, a2 = a * a;
    float d = nh * nh * (a2 - 1.0) + 1.0;
    return a2 / max(3.14159 * d * d, 0.0001);
}
vec3 shade(vec3 albedo, vec3 n, vec2 p, float rough) {
    vec3 v = normalize(vec3(-p * 0.08, 1.5));
    vec3 l[3] = vec3[3](normalize(vec3(-0.7, 0.4, 0.72)), normalize(vec3(0.6, 0.65, 0.5)),
                        normalize(vec3(0.1, -0.8, 0.58)));
    vec3 lc[3] = vec3[3](vec3(1.0, 0.72, 0.42), vec3(0.32, 0.65, 1.0), vec3(0.68, 0.24, 1.0));
    float nv = max(dot(n, v), 0.0);
    vec3 f0 = mix(vec3(0.62), albedo, 0.6);
    vec3 result = albedo * 0.045;
    for (int i = 0; i < 3; ++i) {
        vec3 h = normalize(v + l[i]);
        float nl = max(dot(n, l[i]), 0.0), vh = max(dot(v, h), 0.0);
        vec3 F = f0 + (1.0 - f0) * pow(1.0 - vh, 5.0);
        result += lc[i] * (nl * albedo * 0.08 + ggx(max(dot(n, h), 0.0), rough) * F * nl * 0.24);
    }
    vec3 r = reflect(-v, n);
    vec3 env = mix(vec3(0.015, 0.025, 0.05), film(r.y * 0.18 + r.x * 0.08 + time_f * 0.02),
                   smoothstep(-0.5, 0.8, r.z));
    return result + env * (f0 + (1.0 - f0) * pow(1.0 - nv, 5.0)) * 1.45;
}
void main(void) {
    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    float e = 2.0 / max(max(iResolution.x, iResolution.y), 320.0);
    vec3 n = getNormal(p, e);
    float h = tideHeight(p);
    vec2 flow = n.xy * (0.025 + 0.018 * amp_low) + vec2(sin(h * 4.0), cos(h * 3.0)) * 0.006;
    vec2 uv = mirrorUV(tc + flow);
    float ca = 0.0025 + 0.006 * amp_high;
    vec3 src = vec3(texture(samp, mirrorUV(uv + n.xy * ca)).r, texture(samp, uv).g,
                    texture(samp, mirrorUV(uv - n.xy * ca)).b);
    float y = dot(src, vec3(0.299, 0.587, 0.114));
    vec3 chrome = mix(vec3(y) * vec3(0.78, 0.88, 1.0), src, 0.22);
    float rough = mix(0.09, 0.28, fbm(p * 3.5 + time_f * 0.05));
    vec3 col = shade(chrome, n, p, rough);
    float crest = pow(0.5 + 0.5 * sin(h * 8.0 - time_f * 2.0), 10.0);
    col += film(h * 0.2 + time_f * 0.025) * crest * (0.4 + amp_peak * 1.2);
    color = vec4(tonemap(col * (1.0 + amp_smooth * 0.3)), texture(samp, uv).a);
}
