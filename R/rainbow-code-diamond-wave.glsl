#version 330 core
// rainbow-code-diamond-wave
// Sculpted diamond waves with jewel-like dispersion and crisp microfacet highlights.

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_rms;
uniform float amp_smooth;
uniform float amp_low;
uniform float amp_mid;
uniform float amp_high;
uniform float iamp;

const float TAU = 6.28318530718;
mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}
vec2 mirrorUV(vec2 p) {
    return 1.0 - abs(mod(p, 2.0) - 1.0);
}
vec3 spectral(float x) {
    return .5 + .5 * cos(TAU * (x + vec3(.0, .34, .67)));
}
vec3 aces(vec3 x) {
    x = max(x, 0.0);
    return clamp((x * (2.51 * x + .03)) / (x * (2.43 * x + .59) + .14), 0.0, 1.0);
}
float diamonds(vec2 p) {
    p = rot(.785398) * p;
    float t = time_f * .38;
    vec2 cell = abs(fract(p * vec2(7.0, 9.0) + vec2(t * .12, -t * .08)) - .5);
    float facet = .5 - max(cell.x, cell.y);
    float wave = sin((abs(p.x) + abs(p.y)) * 28.0 - t * 3.2);
    return facet * 1.8 + wave * .085 + sin(p.x * 16.0 - p.y * 7.0 + t) * .045;
}
void main() {
    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 p = (tc - .5) * vec2(aspect, 1.0);
    float e = 1.4 / max(iResolution.y, 360.0);
    float h = diamonds(p), hx = diamonds(p + vec2(e, 0)), hy = diamonds(p + vec2(0, e));
    vec3 n = normalize(vec3((h - hx) * 3.2, (h - hy) * 3.2, e));
    vec2 uv = mirrorUV(tc + n.xy * (.017 + amp_low * .018));
    float split = .003 + amp_high * .013;
    vec2 axis = normalize(n.xy + .0001);
    vec3 src = vec3(texture(samp, mirrorUV(uv + axis * split)).r, texture(samp, uv).g,
                    texture(samp, mirrorUV(uv - axis * split)).b);
    vec3 v = normalize(vec3(-p * .12, 1.2)), l1 = normalize(vec3(-.58, .67, .45)),
         l2 = normalize(vec3(.65, -.2, .73));
    float s1 = pow(max(dot(n, normalize(v + l1)), 0.0), 95.0),
          s2 = pow(max(dot(n, normalize(v + l2)), 0.0), 55.0);
    float fres = pow(1.0 - max(dot(n, v), 0.0), 4.0);
    vec3 gem = spectral(h * .42 + length(p) * .15 - time_f * .024);
    vec3 result = src * (.28 + .65 * max(dot(n, l1), 0.0)) + gem * (.10 + .58 * fres);
    result += s1 * vec3(1.0, .82, .62) * (1.0 + amp_peak * .7) + s2 * gem * .65;
    float edge = pow(1.0 - clamp(h * 2.2, 0.0, 1.0), 12.0);
    result += gem * edge * (.08 + amp_mid * .24);
    color = vec4(aces(result * (1.0 + amp_smooth * .14)), texture(samp, uv).a);
}
