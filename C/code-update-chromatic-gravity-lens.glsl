#version 330 core
// Multi-source gravity lens splitting the image into orbiting spectral Einstein rings.
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform sampler1D spectrum;
uniform float iTime, amp_peak, amp_smooth;
uniform vec2 iResolution;
const float T = 6.28318530718;
vec3 P(float x) {
    return .5 + .5 * cos(T * (x + vec3(.0, .33, .67)));
}
vec2 warp(vec2 p, vec2 o, float k) {
    vec2 d = p - o;
    return d * k / (dot(d, d) + .025);
}
void main() {
    float b = texture(spectrum, .03).r, m = texture(spectrum, .2).r, t = texture(spectrum, .59).r,
          a = texture(spectrum, .86).r;
    float A = iResolution.x / iResolution.y;
    vec2 p = (tc - .5) * vec2(A, 1);
    vec2 o1 = .2 * vec2(cos(iTime * .31), sin(iTime * .43)),
         o2 = .28 * vec2(cos(iTime * .21 + 2.), sin(iTime * .27 + 2.));
    vec2 q = p + warp(p, o1, .018 + .025 * b) + warp(p, o2, .012 + .02 * m);
    vec2 uv = q / vec2(A, 1) + .5;
    vec2 dir = normalize(q - p + vec2(1e-4));
    float ca = .006 + .032 * t;
    vec3 c =
        vec3(texture(samp, uv + dir * ca).r, texture(samp, uv).g, texture(samp, uv - dir * ca).b);
    float d1 = length(p - o1), d2 = length(p - o2);
    float ring = exp(-abs(d1 - (.13 + .03 * b)) * 80.) + exp(-abs(d2 - (.1 + .025 * m)) * 90.);
    float arc = ring * pow(.5 + .5 * cos(atan(p.y, p.x) * 12. - iTime * 1.5), 8.);
    c *= .55 + .55 * P(length(q) * .6 + iTime * .025);
    c += P(d1 - d2 + iTime * .08) * (ring * (.45 + b) + arc * (.4 + 2. * a));
    c *= .9 + .3 * amp_smooth;
    c = mix(c, 1. - c, smoothstep(.95, 1., amp_peak));
    color = vec4(1. - exp(-max(c, 0.) * 1.28), 1);
}
