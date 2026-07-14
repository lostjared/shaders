#version 330 core
// Refractive crystalline ocean with angular breakers and rainbow foam.
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform sampler1D spectrum;
uniform float iTime, amp_peak, amp_smooth;
uniform vec2 iResolution;
const float T = 6.28318530718;
vec3 P(float x) {
    return .5 + .5 * cos(T * (x + vec3(.52, .25, .05)));
}
float W(vec2 p) {
    return sin(p.x * 11. + sin(p.y * 5. + iTime) * 2.) +
           sin(p.y * 15. - iTime * 1.4 + sin(p.x * 4.) * 2.) * .6;
}
void main() {
    float b = texture(spectrum, .03).r, m = texture(spectrum, .19).r, t = texture(spectrum, .57).r,
          a = texture(spectrum, .85).r;
    float A = iResolution.x / iResolution.y;
    vec2 p = (tc - .5) * vec2(A, 1);
    p.y += p.x * p.x * (.25 + b * .15);
    float e = .002, f = W(p);
    vec2 g = vec2(W(p + vec2(e, 0)) - W(p - vec2(e, 0)), W(p + vec2(0, e)) - W(p - vec2(0, e))) /
             (2. * e);
    vec2 uv = tc + g * (.0015 + .003 * m);
    float ca = .001 + .006 * t;
    vec3 c = vec3(texture(samp, uv + g * ca).r, texture(samp, uv).g, texture(samp, uv - g * ca).b);
    float facet = pow(1. - abs(fract(f * 1.7) - .5) * 2., 8.);
    float foam = pow(smoothstep(.6, 1., f * .5 + .5), 8.);
    vec3 crystal = P(f * .08 + p.x * .2 + iTime * .025);
    c = mix(c, c * crystal, .45);
    c += crystal * facet * (.22 + a * .5) + vec3(.65, .85, 1) * foam * (.55 + 2. * b);
    c *= .88 + .32 * amp_smooth;
    c = mix(c, 1. - c, smoothstep(.96, 1., amp_peak));
    color = vec4(1. - exp(-max(c, 0.) * 1.35), 1);
}
