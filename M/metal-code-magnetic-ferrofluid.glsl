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
    return fract(sin(dot(p, vec2(27.1, 117.7))) * 43758.5453);
}
float noise21(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash21(i), hash21(i + vec2(1, 0)), f.x),
               mix(hash21(i + vec2(0, 1)), hash21(i + 1.0), f.x), f.y);
}
float fbm(vec2 p) {
    float s = 0.0, a = 0.5;
    for (int i = 0; i < 5; ++i) {
        s += a * noise21(p);
        p = mat2(0.6, -0.8, 0.8, 0.6) * p * 2.11 + 3.1;
        a *= 0.5;
    }
    return s;
}
vec2 mirrorUV(vec2 p) {
    return 1.0 - abs(mod(p, 2.0) - 1.0);
}
vec3 spectral(float t) {
    return 0.52 + 0.48 * cos(6.2831853 * (t + vec3(0.0, 0.32, 0.68)));
}
vec3 tone(vec3 x) {
    return 1.0 - exp(-max(x, 0.0) * 1.15);
}

float ferro(vec2 p) {
    float t = time_f;
    vec2 o = vec2(cos(t * 0.63), sin(t * 0.57)) * 0.34;
    vec2 poles[3] = vec2[3](o, -o, vec2(sin(t * 0.39), cos(t * 0.44)) * 0.18);
    float field = 0.0;
    for (int i = 0; i < 3; ++i) {
        vec2 d = p - poles[i];
        float r = length(d) + 0.045;
        float a = atan(d.y, d.x);
        float signv = (i == 1) ? -1.0 : 1.0;
        field += sin(a * (8.0 + float(i) * 2.0) + signv / r * 2.2 - t * (2.0 + float(i))) /
                 (1.0 + r * 2.5);
    }
    float grain = fbm(p * 7.0 + t * 0.08);
    return field * 0.52 + grain * 0.3 + sin(length(p) * 45.0 - t * 7.0) * 0.08;
}
vec3 normalAt(vec2 p, float e) {
    float h = ferro(p);
    vec2 g = vec2(ferro(p + vec2(e, 0)) - h, ferro(p + vec2(0, e)) - h) / e;
    return normalize(vec3(-g * 0.16, 1));
}
float spec(vec3 n, vec3 v, vec3 l, float power) {
    return pow(max(dot(n, normalize(v + l)), 0.0), power);
}
void main(void) {
    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    float e = 2.0 / max(max(iResolution.x, iResolution.y), 320.0);
    float h = ferro(p);
    vec3 n = normalAt(p, e);
    vec2 uv = mirrorUV(tc + n.xy * (0.026 + amp_low * 0.025));
    float split = 0.0025 + amp_high * 0.006;
    vec3 src = vec3(texture(samp, mirrorUV(uv + n.xy * split)).r, texture(samp, uv).g,
                    texture(samp, mirrorUV(uv - n.xy * split)).b);
    float y = dot(src, vec3(0.299, 0.587, 0.114));
    vec3 base = mix(vec3(y) * vec3(0.72, 0.78, 0.86), src, 0.2);
    vec3 v = normalize(vec3(-p * 0.08, 1.5)), l0 = normalize(vec3(-0.65, 0.48, 0.72)),
         l1 = normalize(vec3(0.72, 0.22, 0.66));
    float nv = max(dot(n, v), 0.0);
    vec3 f0 = mix(vec3(0.62), base, 0.58);
    vec3 F = f0 + (1.0 - f0) * pow(1.0 - nv, 5.0);
    vec3 refl = spectral(dot(reflect(-v, n), vec3(0.4, 0.25, 0.35)) * 0.3 + time_f * 0.02);
    vec3 col = base * (0.04 + 0.13 * max(dot(n, l0), 0.0)) +
               F * (refl * 0.85 + spec(n, v, l0, 150.0) * vec3(1.0, 0.82, 0.62) * 2.5 +
                    spec(n, v, l1, 40.0) * vec3(0.25, 0.55, 1.2));
    float spike = pow(0.5 + 0.5 * sin(h * 15.0 - time_f * 3.0), 12.0);
    col += spectral(h * 0.4 + time_f * 0.03) * spike * (0.45 + amp_peak * 1.3);
    color = vec4(tone(col * (1.0 + amp_smooth * 0.3)), texture(samp, uv).a);
}
