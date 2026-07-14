#version 330 core
// Perspective nave of laser arches terminating in a radiant spectrum rose window.
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform sampler1D spectrum;
uniform float iTime, amp_peak, amp_smooth;
uniform vec2 iResolution;
const float T = 6.28318530718;
vec3 P(float x) {
    return .5 + .5 * cos(T * (x + vec3(.02, .31, .64)));
}
void main() {
    float b = texture(spectrum, .03).r, m = texture(spectrum, .2).r, t = texture(spectrum, .6).r,
          a = texture(spectrum, .88).r;
    float A = iResolution.x / iResolution.y;
    vec2 p = (tc - .5) * vec2(A, 1);
    float z = 1. / max(.12, p.y + .72), x = p.x * z;
    float aisle = pow(.5 + .5 * cos(x * 18.), 22.);
    float depth = pow(.5 + .5 * cos(z * 8. - iTime * (1. + b)), 18.);
    float arch = exp(-abs(length(vec2(x * .45, (p.y + .1) * z)) - (.5 + .08 * m)) * 35.) *
                 smoothstep(-.4, .25, p.y);
    vec2 uv = fract(vec2(x * .16 + .5, z * .14));
    float ca = .005 + .025 * t;
    vec3 c = vec3(texture(samp, uv + ca).r, texture(samp, uv).g, texture(samp, uv - ca).b) *
             (.38 + .55 * P(z * .03));
    float r = length(p - vec2(0, .12)), an = atan(p.y - .12, p.x);
    float rose = pow(max(cos(an * 12. + iTime * .2), 0.), 16.) * exp(-abs(r - .15) * 65.);
    c += P(z * .04 - iTime * .06) * (aisle * depth * (.35 + a) + arch * (.6 + 1.5 * b)) +
         P(an / T + iTime * .05) * rose * (.8 + 2. * a);
    c *= .9 + .32 * amp_smooth;
    c = mix(c, 1. - c, smoothstep(.95, 1., amp_peak));
    color = vec4(1. - exp(-max(c, 0.) * 1.3), 1);
}
