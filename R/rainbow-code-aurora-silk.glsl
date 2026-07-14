#version 330 core
// rainbow-code-aurora-silk
// Flowing iridescent silk: layered domain warping, fine weave, and soft studio light.

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
    float s = 0.0, a = 0.5;
    mat2 m = mat2(.80, -.60, .60, .80);
    for (int i = 0; i < 6; i++) {
        s += a * noise21(p);
        p = m * p * 2.03 + 1.7;
        a *= .5;
    }
    return s;
}
vec2 mirrorUV(vec2 p) {
    return 1.0 - abs(mod(p, 2.0) - 1.0);
}
vec3 spectral(float x) {
    return .5 + .5 * cos(TAU * (x + vec3(0.00, .34, .68)));
}
vec3 aces(vec3 x) {
    x = max(x, 0.0);
    return clamp((x * (2.51 * x + .03)) / (x * (2.43 * x + .59) + .14), 0.0, 1.0);
}

float cloth(vec2 p) {
    float t = time_f * .18;
    vec2 q = vec2(fbm(p * 2.1 + vec2(t, -t * .7)), fbm(p * 2.1 + vec2(8.3 - t * .6, 3.1 + t)));
    vec2 w = p + (q - .5) * (.78 + amp_low * .22);
    float folds =
        sin(w.x * 13.0 + w.y * 4.0 - t * 8.0) + .55 * sin(w.y * 21.0 - w.x * 5.0 + t * 5.0);
    float weave = .12 * sin(w.x * 92.0) * sin(w.y * 88.0);
    return folds * .34 + fbm(w * 5.0) * .65 + weave;
}
void main() {
    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 p = (tc - .5) * vec2(aspect, 1.0);
    float px = 2.0 / max(iResolution.y, 360.0);
    float h = cloth(p), hx = cloth(p + vec2(px, 0)), hy = cloth(p + vec2(0, px));
    vec3 n = normalize(vec3((h - hx) * 5.2, (h - hy) * 5.2, px));
    vec2 flow = n.xy * (.018 + amp_low * .018);
    vec2 uv = mirrorUV(tc + flow);
    float split = .0025 + amp_high * .009;
    vec3 src = vec3(texture(samp, mirrorUV(uv + n.xy * split)).r, texture(samp, uv).g,
                    texture(samp, mirrorUV(uv - n.xy * split)).b);
    vec3 v = normalize(vec3(-p * .12, 1.4)), l = normalize(vec3(-.45, .72, .62)),
         halfV = normalize(v + l);
    float diff = max(dot(n, l), 0.0), spec = pow(max(dot(n, halfV), 0.0), 70.0);
    float fres = pow(1.0 - max(dot(n, v), 0.0), 4.0);
    vec3 film = spectral(h * .32 + n.x * .13 + time_f * .025);
    vec3 result = src * (.36 + .58 * diff) + film * (.18 + .62 * fres) + spec * vec3(1.1, .92, .78);
    result += film * pow(.5 + .5 * sin(h * 18.0), 10.0) * (.08 + amp_peak * .4);
    color = vec4(aces(result * (1.0 + amp_smooth * .2)), texture(samp, uv).a);
}
