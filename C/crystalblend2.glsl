#version 330 core
in vec2 tc;
out vec4 color;
uniform float time_f;
uniform sampler2D samp;
uniform vec2 iResolution;
uniform float amp;
uniform float uamp;
uniform int blendMode;
uniform float blendAmt;

float PI = 3.141592653589793;

float mirror1(float x, float m) {
    float p = mod(x, m * 2.0);
    return p > m ? (2.0 * m - p) : p;
}

vec2 kaleido(vec2 p, float seg) {
    vec2 c = vec2(0.5);
    vec2 d = p - c;
    float a = atan(d.y, d.x);
    float r = length(d);
    float m = PI / max(2.0, seg);
    a = mirror1(a, m);
    return c + vec2(cos(a), sin(a)) * max(r, 1e-6);
}

uvec3 to8(vec3 c) {
    return uvec3(clamp(round(c * 255.0), 0.0, 255.0));
}
vec3 from8(uvec3 x) {
    return vec3(x) / 255.0;
}

vec3 xorBlend(vec3 a, vec3 b) {
    uvec3 ai = to8(a);
    uvec3 bi = to8(b);
    return from8(ai ^ bi);
}

vec3 median3(vec3 a, vec3 b, vec3 c) {
    vec3 mn = min(a, min(b, c));
    vec3 mx = max(a, max(b, c));
    return a + b + c - mn - mx;
}

void main() {
    vec2 uv = tc;
    float drive = clamp(amp + uamp, 0.0, 2.0);
    float seg = floor(mix(5.0, 12.0, clamp(drive * 0.5, 0.0, 1.0)));
    vec2 k0 = kaleido(sin(uv * time_f), seg);
    float r0 = length(k0 - 0.5);
    vec2 dir0 = normalize(k0 - 0.5 + vec2(1e-6, 0.0));
    float bend0 = (0.05 + 0.12 * uamp) / (r0 + 0.04);
    vec2 wob0 = 0.010 * (0.3 + amp) * vec2(sin(30.0 * r0 - 1.6 * time_f), cos(26.0 * r0 - 1.2 * time_f));
    vec2 wuv0 = k0 + dir0 * bend0 + wob0;

    vec2 k1 = kaleido(uv + 0.003 * vec2(sin(time_f * 0.7), cos(time_f * 0.6)), seg);
    float r1 = length(k1 - 0.5);
    vec2 dir1 = normalize(k1 - 0.5 + vec2(1e-6, 0.0));
    float bend1 = (0.04 + 0.10 * uamp) / (r1 + 0.05);
    vec2 wob1 = 0.009 * (0.3 + amp) * vec2(cos(27.0 * r1 - 1.3 * time_f), sin(25.0 * r1 - 1.1 * time_f));
    vec2 wuv1 = k1 + dir1 * bend1 + wob1;

    vec3 a = texture(samp, uv).rgb;
    vec3 b = texture(samp, wuv0).rgb;
    vec3 c3 = texture(samp, wuv1).rgb;

    vec3 blended = (blendMode == 1) ? xorBlend(a, b) : median3(a, b, c3);

    float s = clamp(mix(0.35, 0.85, blendAmt) * (0.6 + 0.4 * clamp(drive * 0.5, 0.0, 1.0)), 0.0, 1.0);
    float edge = smoothstep(0.0, 0.9, length(uv - 0.5));
    float adaptive = mix(s * 0.7, s, edge);
    vec3 outc = mix(a, blended, adaptive);

    color = vec4(outc, 1.0);
}
