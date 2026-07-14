#version 330 core
// rainbow-code-neon-topography
// Fine spectral contour lines over a dimensional, audio-responsive terrain surface.

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
float terrain(vec2 p) {
    float s = 0.0, a = .52;
    mat2 m = mat2(.82, -.57, .57, .82);
    for (int i = 0; i < 6; i++) {
        s += a * noise21(p);
        p = m * p * 2.02 + 1.3;
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
void main() {
    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 p = (tc - .5) * vec2(aspect, 1.0), q = p * 3.7 + vec2(time_f * .045, -time_f * .032);
    float e = 2.0 / max(iResolution.y, 360.0), h = terrain(q), hx = terrain(q + vec2(e, 0)),
          hy = terrain(q + vec2(0, e));
    vec3 n = normalize(vec3((h - hx) * 2.9, (h - hy) * 2.9, e));
    vec2 uv = mirrorUV(tc + n.xy * (.012 + amp_low * .014));
    vec3 src = texture(samp, uv).rgb;
    float bands = fract(h * (13.0 + amp_mid * 4.0) - time_f * .14);
    float line = 1.0 - smoothstep(.025 + .015 * amp_high, .085 + .02 * amp_high, abs(bands - .5));
    float major = 1.0 - smoothstep(.035, .11, abs(fract(h * 3.0) - .5));
    vec3 hue = spectral(h * .8 + dot(p, vec2(.06, .11)) - time_f * .02);
    vec3 l = normalize(vec3(-.5, .62, .64));
    float shade = .32 + .68 * max(dot(n, l), 0.0);
    vec3 result = src * shade * .82 + src * hue * .18;
    result += hue * line * (.18 + amp_peak * .58) + hue * major * .09;
    result += pow(max(dot(n, normalize(vec3(.45, -.2, .87))), 0.0), 70.0) * .25;
    color = vec4(aces(result * (1.0 + amp_rms * .18)), texture(samp, uv).a);
}
