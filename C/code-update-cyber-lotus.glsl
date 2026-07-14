#version 330 core
// Nested neon lotus petals with mirrored circuit-like texture channels.
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform sampler1D spectrum;
uniform float iTime, amp_peak, amp_smooth;
uniform vec2 iResolution;
const float T = 6.28318530718;
vec3 P(float x) {
    return .5 + .5 * cos(T * (x + vec3(.12, .42, .78)));
}
void main() {
    float b = texture(spectrum, .03).r, m = texture(spectrum, .18).r, t = texture(spectrum, .55).r,
          a = texture(spectrum, .84).r;
    float A = iResolution.x / iResolution.y;
    vec2 p = (tc - .5) * vec2(A, 1);
    float r = length(p), an = atan(p.y, p.x), pet = 10. + floor(b * 6.);
    float f = abs(cos(an * pet * .5 + iTime * .18));
    float rr = r * (1. + .34 * f * m);
    vec2 q = vec2(cos(an), sin(an)) * rr;
    for (int i = 0; i < 3; i++) {
        q = abs(fract(q * 1.7 + .5) - .5);
        q = q.yx * vec2(1, -1) + .08 * sin(iTime + float(i));
    }
    vec2 uv = fract(q / vec2(A, 1) + .5);
    float ca = .004 + .02 * t;
    vec3 c = vec3(texture(samp, uv + vec2(ca, 0)).r, texture(samp, uv).g,
                  texture(samp, uv - vec2(ca, 0)).b);
    float petals = exp(-abs(r - (.12 + .055 * floor(r / .055) + .045 * f)) * 85.);
    float veins = pow(.5 + .5 * cos(an * pet - r * 42. + iTime * 1.4), 16.);
    c *= .48 + .62 * P(an / T + r + iTime * .03);
    c += P(an / T - r * 1.4 - iTime * .08) *
         (petals * (.5 + 1.6 * b) + veins * exp(-r * 2.) * (.25 + 1.8 * a));
    c *= .9 + .3 * amp_smooth;
    c = mix(c, 1. - c, smoothstep(.95, 1., amp_peak));
    color = vec4(1. - exp(-max(c, 0.) * 1.25), 1);
}
