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
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}
float noise21(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash21(i), hash21(i + vec2(1, 0)), f.x),
               mix(hash21(i + vec2(0, 1)), hash21(i + 1.0), f.x), f.y);
}
float fbm(vec2 p) {
    float f = 0.0, a = 0.5;
    mat2 m = mat2(0.80, -0.60, 0.60, 0.80);
    for (int i = 0; i < 5; ++i) {
        f += a * noise21(p);
        p = m * p * 2.03 + 1.7;
        a *= 0.5;
    }
    return f;
}
vec2 repeatMirror(vec2 p) {
    return 1.0 - abs(mod(p, 2.0) - 1.0);
}
vec3 spectral(float x) {
    return 0.55 + 0.45 * cos(TAU * (x + vec3(0.00, 0.31, 0.67)));
}
vec3 aces(vec3 x) {
    return clamp((x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14), 0.0, 1.0);
}

float heightField(vec2 p) {
    float t = time_f;
    float nave = fbm(p * 2.8 + vec2(0.0, -t * 0.22));
    // Rounded symmetry preserves the cathedral shape without an abs() normal cusp at x = 0.
    float archX = sqrt(p.x * p.x + 0.0036);
    float arches = cos(archX * (13.0 + amp_mid * 5.0) - p.y * 4.0 + nave * 3.0);
    float ribs = sin(length(p * vec2(0.7, 1.0)) * 31.0 - t * 5.0 + nave * 5.0);
    float drops = sin(p.y * 17.0 + sin(p.x * 9.0 + t) * 2.5 - t * 3.0);
    return nave * 0.6 + arches * 0.22 + ribs * 0.12 + drops * 0.08;
}

vec3 normalAt(vec2 p, float e) {
    float h = heightField(p);
    vec2 g = vec2(heightField(p + vec2(e, 0)) - h, heightField(p + vec2(0, e)) - h) / e;
    return normalize(vec3(-g * 0.22, 1.0));
}

vec3 metalLight(vec3 base, vec3 n, vec2 p, float rough) {
    vec3 v = normalize(vec3(-p * 0.12, 1.8));
    vec3 l0 = normalize(vec3(-0.55, 0.65, 0.80));
    vec3 l1 = normalize(vec3(0.72, -0.18, 0.67));
    float nv = max(dot(n, v), 0.0);
    vec3 f0 = mix(vec3(0.55), base, 0.72);
    vec3 fres = f0 + (1.0 - f0) * pow(1.0 - nv, 5.0);
    float s0 = pow(max(dot(n, normalize(v + l0)), 0.0), mix(180.0, 22.0, rough));
    float s1 = pow(max(dot(n, normalize(v + l1)), 0.0), mix(110.0, 15.0, rough));
    vec3 r = reflect(-v, n);
    vec3 env = mix(vec3(0.025, 0.04, 0.07), spectral(r.x * 0.18 + r.y * 0.13 + time_f * 0.025),
                   0.62 + 0.25 * r.z);
    vec3 direct = vec3(1.0, 0.88, 0.72) * s0 * 2.4 + vec3(0.28, 0.58, 1.0) * s1 * 1.5;
    return base * (0.08 + 0.18 * max(dot(n, l0), 0.0)) + env * fres * 1.25 + direct * fres;
}

void main(void) {
    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    float e = 2.0 / max(max(iResolution.x, iResolution.y), 320.0);
    vec3 n = normalAt(p, e);
    vec2 flow = n.xy * (0.032 + amp_low * 0.025);
    vec2 uv = repeatMirror(tc + flow);
    float dispersion = 0.003 + amp_high * 0.008;
    vec3 tex = vec3(texture(samp, repeatMirror(uv + n.xy * dispersion)).r, texture(samp, uv).g,
                    texture(samp, repeatMirror(uv - n.xy * dispersion)).b);
    float lum = dot(tex, vec3(0.299, 0.587, 0.114));
    vec3 alloy = mix(vec3(lum) * vec3(0.82, 0.90, 1.0), tex, 0.28);
    float h = heightField(p);
    vec3 lit = metalLight(alloy, n, p, 0.18 + 0.12 * fbm(p * 5.0));
    float nave = pow(0.5 + 0.5 * sin(h * 13.0 - time_f * 2.0), 7.0);
    lit += spectral(h * 0.4 + time_f * 0.03) * nave * (0.35 + amp_peak);
    color = vec4(aces(lit * (1.0 + amp_smooth * 0.35)), texture(samp, uv).a);
}
