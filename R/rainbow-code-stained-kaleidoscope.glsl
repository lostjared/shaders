#version 330 core
// rainbow-code-stained-kaleidoscope
// Precision stained-glass kaleidoscope with lead seams, refraction, and luminous color.

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

const float PI = 3.14159265359;
const float TAU = 6.28318530718;
mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}
vec2 mirrorUV(vec2 p) {
    return 1.0 - abs(mod(p, 2.0) - 1.0);
}
vec3 spectral(float x) {
    return .5 + .5 * cos(TAU * (x + vec3(0.0, .34, .67)));
}
vec3 aces(vec3 x) {
    x = max(x, 0.0);
    return clamp((x * (2.51 * x + .03)) / (x * (2.43 * x + .59) + .14), 0.0, 1.0);
}
vec2 kaleido(vec2 p, float sectors) {
    float a = atan(p.y, p.x), r = length(p), w = TAU / sectors;
    a = abs(mod(a + .5 * w, w) - .5 * w);
    return vec2(cos(a), sin(a)) * r;
}
void main() {
    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 p = (tc - .5) * vec2(aspect, 1.0);
    p = rot(time_f * .055 + amp_smooth * .08) * p;
    float sectors = 8.0 + floor(amp_mid * 4.0) * 2.0;
    vec2 k = kaleido(p, sectors);
    float r = length(k);
    k = abs(k - vec2(.16 + sin(r * 13.0 - time_f) * .018, .0));
    float gridX = abs(fract(k.x * 7.0) - .5), gridY = abs(fract((k.y + k.x * .42) * 8.0) - .5);
    float seam = 1.0 - smoothstep(.025, .055, min(gridX, gridY));
    vec2 cell = floor(k * vec2(7.0, 8.0));
    float id = fract(sin(dot(cell, vec2(37.1, 91.7))) * 43758.5453);
    vec2 refr = (vec2(gridX, gridY) - .25) * (.032 + amp_low * .015);
    vec2 uv = mirrorUV(k / vec2(aspect, 1.0) + .5 + refr);
    float split = .0025 + amp_high * .009;
    vec2 axis = normalize(k + .001);
    vec3 src = vec3(texture(samp, mirrorUV(uv + axis * split)).r, texture(samp, uv).g,
                    texture(samp, mirrorUV(uv - axis * split)).b);
    vec3 glass = spectral(id * .68 + r * .42 - time_f * .028);
    float bevel = pow(1.0 - smoothstep(.06, .2, min(gridX, gridY)), 2.0);
    vec3 result = mix(src, src * glass * 1.45, .48) + glass * bevel * (.10 + amp_peak * .35);
    result = mix(result, result * .10, seam * .88);
    result += glass * seam * amp_high * .12;
    result += glass * exp(-r * 3.5) * (.05 + amp_rms * .12);
    color = vec4(aces(result), texture(samp, uv).a);
}
