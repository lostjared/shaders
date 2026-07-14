#version 330 core
// rainbow-code-chromatic-ribbons
// Layered satin ribbons with spectral edge light and coherent texture flow.

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
vec2 mirrorUV(vec2 p) {
    return 1.0 - abs(mod(p, 2.0) - 1.0);
}
vec3 spectral(float x) {
    vec3 c = .5 + .5 * cos(TAU * (x + vec3(.0, .33, .67)));
    return mix(c, c * c, 0.3);
}
vec3 aces(vec3 x) {
    x = max(x, 0.0);
    return clamp((x * (2.51 * x + .03)) / (x * (2.43 * x + .59) + .14), 0.0, 1.0);
}
float ribbons(vec2 p) {
    float t = time_f * .42;
    p.x += sin(p.y * 3.0 - t) * .16;
    float f1 = sin(p.x * 17.0 + sin(p.y * 8.0 + t) * 1.8 - t * 2.3);
    float f2 = sin(p.x * 9.0 - p.y * 13.0 + t * 1.7);
    float f3 = sin(p.x * 31.0 + p.y * 4.0 - t * 3.1);
    return f1 * .48 + f2 * .27 + f3 * .12;
}
void main() {
    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 p = (tc - .5) * vec2(aspect, 1.0);
    float e = 1.6 / max(iResolution.y, 360.0), h = ribbons(p), hx = ribbons(p + vec2(e, 0)),
          hy = ribbons(p + vec2(0, e));
    vec3 n = normalize(vec3((h - hx) * 4.2, (h - hy) * 4.2, e));
    vec2 uv = mirrorUV(tc + n.xy * (.014 + amp_low * .018));
    float split = .002 + amp_high * .009;
    vec3 src = vec3(texture(samp, mirrorUV(uv + n.xy * split)).r, texture(samp, uv).g,
                    texture(samp, mirrorUV(uv - n.xy * split)).b);
    vec3 v = normalize(vec3(-p * .1, 1.0)), l = normalize(vec3(-.6, .55, .62)),
         hv = normalize(v + l);
    float diff = .25 + .75 * max(dot(n, l), 0.0), spec = pow(max(dot(n, hv), 0.0), 90.0);
    float rim = pow(1.0 - max(dot(n, v), 0.0), 4.0);
    float edge = pow(abs(cos(h * 3.14159)), 18.0);
    vec3 hue = spectral(h * .15 + p.y * .1 - time_f * .025);
    vec3 result = src * diff * mix(vec3(1.0), hue, .28) + hue * rim * .55;
    result += vec3(1.0, .88, .72) * spec * (.5 + amp_peak) + hue * edge * amp_mid * .18;
    color = vec4(aces(result * (1.0 + amp_smooth * .16)), texture(samp, uv).a);
}
