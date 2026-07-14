#version 330 core
// rainbow-code-prismatic-caustics
// Clean refractive caustics with spectral focusing and sub-pixel texture dispersion.

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
vec3 spectrum(float x) {
    return .5 + .5 * cos(TAU * (x + vec3(0.02, .35, .68)));
}
vec3 aces(vec3 x) {
    x = max(x, 0.0);
    return clamp((x * (2.51 * x + .03)) / (x * (2.43 * x + .59) + .14), 0.0, 1.0);
}
float waves(vec2 p) {
    float t = time_f * (.65 + amp_smooth * .18);
    float a = sin(dot(p, vec2(18.0, 11.0)) + t * 2.1);
    float b = sin(dot(p, vec2(-13.0, 24.0)) - t * 1.7);
    float c = sin(length(p - vec2(sin(t * .23), cos(t * .19)) * .25) * 31.0 - t * 3.4);
    float d = sin(p.x * 47.0 + sin(p.y * 9.0 - t) * 2.0 + t);
    return a * .38 + b * .29 + c * .22 + d * .11;
}
void main() {
    float aspect = max(iResolution.x, 1.0) / max(iResolution.y, 1.0);
    vec2 p = (tc - .5) * vec2(aspect, 1.0);
    float e = 1.5 / max(iResolution.y, 360.0);
    float h = waves(p), hx = waves(p + vec2(e, 0)), hy = waves(p + vec2(0, e));
    vec2 grad = vec2(hx - h, hy - h) / e;
    vec3 n = normalize(vec3(-grad * .055, 1.0));
    vec2 refractOffset = n.xy * (.025 + amp_low * .018);
    vec2 uv = mirrorUV(tc + refractOffset);
    float dispersion = .002 + .008 * amp_high + .0025 * length(grad);
    vec2 axis = normalize(n.xy + vec2(.0001));
    vec3 src = vec3(texture(samp, mirrorUV(uv + axis * dispersion)).r, texture(samp, uv).g,
                    texture(samp, mirrorUV(uv - axis * dispersion)).b);
    vec3 l = normalize(vec3(-.35, .55, .76));
    float focus = pow(max(dot(n, l), 0.0), 18.0);
    float ridge = pow(clamp(length(grad) * .075, 0.0, 1.0), 1.7);
    vec3 prism = spectrum(h * .16 + dot(p, vec2(.09, .13)) - time_f * .035);
    vec3 result = src * (.70 + .28 * max(n.z, 0.0));
    result += prism * focus * (.35 + amp_peak * .8) + prism * ridge * (.10 + amp_mid * .28);
    result += pow(max(dot(n, normalize(vec3(.6, -.3, .74))), 0.0), 80.0) * .55;
    color = vec4(aces(result * (1.0 + amp_rms * .22)), texture(samp, uv).a);
}
