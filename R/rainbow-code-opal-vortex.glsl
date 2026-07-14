#version 330 core
// rainbow-code-opal-vortex
// Deep opal vortex with thin-film color, curved reflections, and restrained bloom.

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
    vec3 c = .5 + .5 * cos(TAU * (x + vec3(0.0, .34, .67)));
    return c * c * (3.0 - 2.0 * c);
}
vec3 aces(vec3 x) {
    x = max(x, 0.0);
    return clamp((x * (2.51 * x + .03)) / (x * (2.43 * x + .59) + .14), 0.0, 1.0);
}
float field(vec2 p) {
    float r = length(p) + .025, a = atan(p.y, p.x), t = time_f * .35;
    float spiral = sin(a * 7.0 - log(r) * 8.0 - t * 3.1);
    float rings = sin(r * 38.0 - a * 3.0 + t * 2.4);
    float pearl = sin((p.x + sin(p.y * 7.0 + t) * .12) * 28.0 - t);
    return spiral * .38 + rings * .25 + pearl * .12 + sin(r * 12.0 - t) * .18;
}
void main() {
    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 p = (tc - .5) * vec2(aspect, 1.0), rp = rot(time_f * .04) * p;
    float e = 1.7 / max(iResolution.y, 360.0), h = field(rp), hx = field(rp + vec2(e, 0)),
          hy = field(rp + vec2(0, e));
    vec3 n = normalize(vec3((h - hx) * 3.8, (h - hy) * 3.8, e));
    float r = length(p), a = atan(p.y, p.x);
    vec2 tangent = normalize(vec2(-p.y, p.x) + .0001);
    vec2 uv = mirrorUV(tc + n.xy * (.015 + amp_low * .018) + tangent * sin(h * 4.0) * .009);
    float d = .0025 + amp_high * .010;
    vec3 src = vec3(texture(samp, mirrorUV(uv + n.xy * d)).r, texture(samp, uv).g,
                    texture(samp, mirrorUV(uv - n.xy * d)).b);
    vec3 v = normalize(vec3(-p * .18, 1.2));
    float fres = pow(1.0 - max(dot(v, n), 0.0), 3.5);
    float highlight = pow(max(dot(n, normalize(vec3(-.5, .65, .58))), 0.0), 52.0);
    // Keep the hue periodic across the -PI/PI boundary of atan.
    float angularFlow = sin(a * 3.0 + r * 4.0) * .04;
    vec3 opal = spectral(h * .21 + r * .32 + angularFlow - time_f * .018);
    vec3 result = mix(src, src * opal * 1.35, .28 + amp_mid * .18) + opal * (.14 + .72 * fres);
    result += highlight * mix(vec3(1.0, .82, .64), opal, .35) * (1.0 + amp_peak * .55);
    result += opal * pow(.5 + .5 * sin(h * 13.0), 14.0) * amp_peak * .32;
    color = vec4(aces(result), texture(samp, uv).a);
}
