#version 330 core
// rainbow-code-liquid-pearl
// Pearlescent liquid lens with smooth cellular membranes and thin-film reflections.

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
    float s = 0.0, a = .5;
    mat2 m = mat2(.8, -.6, .6, .8);
    for (int i = 0; i < 5; i++) {
        s += a * noise21(p);
        p = m * p * 2.05 + 2.1;
        a *= .5;
    }
    return s;
}
vec2 mirrorUV(vec2 p) {
    return 1.0 - abs(mod(p, 2.0) - 1.0);
}
vec3 spectral(float x) {
    return .5 + .5 * cos(TAU * (x + vec3(.0, .33, .67)));
}
vec3 aces(vec3 x) {
    x = max(x, 0.0);
    return clamp((x * (2.51 * x + .03)) / (x * (2.43 * x + .59) + .14), 0.0, 1.0);
}
float pearl(vec2 p) {
    float t = time_f * .15;
    vec2 q = vec2(fbm(p * 2.8 + vec2(t, 0)), fbm(p * 2.8 + vec2(5.2, -t)));
    p += (q - .5) * .55;
    return fbm(p * 6.0) - .5 + .14 * sin(p.x * 24.0 - p.y * 9.0 + t * 6.0);
}
void main() {
    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 p = (tc - .5) * vec2(aspect, 1.0);
    float e = 1.8 / max(iResolution.y, 360.0);
    float h = pearl(p), hx = pearl(p + vec2(e, 0)), hy = pearl(p + vec2(0, e));
    vec3 n = normalize(vec3((h - hx) * 5.0, (h - hy) * 5.0, e));
    vec2 uv = mirrorUV(tc + n.xy * (.021 + amp_low * .019));
    float split = .002 + amp_high * .010;
    vec3 src = vec3(texture(samp, mirrorUV(uv + n.xy * split)).r, texture(samp, uv).g,
                    texture(samp, mirrorUV(uv - n.xy * split)).b);
    vec3 v = normalize(vec3(-p * .14, 1.25));
    float fres = pow(1.0 - max(dot(n, v), 0.0), 4.5);
    vec3 pearlHue = mix(vec3(.93, .91, .86), spectral(h * .38 + n.x * .11 - time_f * .018), .62);
    float gleam = pow(max(dot(n, normalize(vec3(-.45, .7, .57))), 0.0), 64.0);
    float membrane = pow(clamp(abs(h) * 3.2, 0.0, 1.0), 8.0);
    vec3 result = mix(src, src * pearlHue * 1.18, .28) + pearlHue * (.12 + .66 * fres);
    result +=
        gleam * vec3(1.0, .9, .78) * (1.0 + amp_peak * .65) + pearlHue * membrane * amp_mid * .16;
    color = vec4(aces(result * (1.0 + amp_smooth * .12)), texture(samp, uv).a);
}
