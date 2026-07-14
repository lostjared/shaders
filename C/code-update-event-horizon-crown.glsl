#version 330 core
// Gravitational log-polar lens with accretion crown and RGB caustics.
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform sampler1D spectrum;
uniform float iTime, amp_peak, amp_smooth;
uniform vec2 iResolution;
const float TAU = 6.28318530718;
vec3 pal(float x) {
    return .5 + .5 * cos(TAU * (x + vec3(.0, .18, .48)));
}
vec2 lens(vec2 p, float z) {
    float r = length(p) + .018, a = atan(p.y, p.x);
    a += 1.25 / r + z;
    return vec2(cos(a), sin(a)) * abs(log(r) * .19 + .36);
}
void main() {
    float b = texture(spectrum, .03).r, m = texture(spectrum, .2).r, t = texture(spectrum, .6).r,
          a = texture(spectrum, .88).r;
    float asp = iResolution.x / iResolution.y;
    vec2 p = (tc - .5) * vec2(asp, 1);
    float r = length(p), an = atan(p.y, p.x);
    float pulse = .04 * b + .015 * sin(iTime * 1.7);
    vec2 q = lens(p, iTime * .16 + b * .7);
    q.x /= asp;
    q += .5;
    vec2 tangent = normalize(vec2(-p.y, p.x) + vec2(1e-4));
    float ca = .006 + .03 * t;
    vec3 c = vec3(texture(samp, fract(q + tangent * ca)).r, texture(samp, fract(q)).g,
                  texture(samp, fract(q - tangent * ca)).b);
    float disk = exp(-abs(r - (.27 + pulse)) * (48. - m * 12.));
    float crown =
        pow(.5 + .5 * cos(an * 11. - log(r + .03) * 7. + iTime * 2.), 10.) * exp(-r * 2.2);
    float photon = exp(-abs(r - .16 - b * .025) * 95.);
    c *= .58 + .55 * pal(an / TAU + iTime * .04);
    c += pal(an / TAU + r * 1.4 + iTime * .1) *
         (disk * (1.2 + 3. * b) + crown * (.35 + 1.8 * a) + photon * 1.5);
    c *= smoothstep(.055, .13, r);
    c += pal(iTime * .08) * exp(-r * 24.) * .5;
    c = mix(c, c.bgr, .2 * m);
    c *= .9 + .28 * amp_smooth;
    c = mix(c, 1. - c, smoothstep(.965, 1., amp_peak));
    color = vec4(1. - exp(-max(c, 0.) * 1.15), 1);
}
