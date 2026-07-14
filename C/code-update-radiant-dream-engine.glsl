#version 330 core
// Grand synthesis: recursive mandala, fluid lens, star dust, and spectral bloom.
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform sampler1D spectrum;
uniform float iTime, amp_peak, amp_smooth;
uniform vec2 iResolution;
const float T = 6.28318530718;
mat2 R(float x) {
    float c = cos(x), s = sin(x);
    return mat2(c, -s, s, c);
}
float H(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5);
}
vec3 P(float x) {
    return .5 + .5 * cos(T * (x + vec3(.03, .36, .69)));
}
void main() {
    float b = texture(spectrum, .03).r, m = texture(spectrum, .21).r, t = texture(spectrum, .6).r,
          a = texture(spectrum, .88).r;
    float A = iResolution.x / iResolution.y;
    vec2 p = (tc - .5) * vec2(A, 1);
    float r = length(p), an = atan(p.y, p.x), seg = 10. + floor(b * 6.), w = T / seg,
          k = abs(mod(an + w * .5, w) - w * .5);
    vec2 q = vec2(cos(k), sin(k)) * r;
    q *= R(iTime * .06);
    float glow = 0.;
    for (int i = 0; i < 5; i++) {
        q = abs(q) * 1.38 - vec2(.34, .24);
        q *= R(.3 + float(i) * .39);
        glow += exp(-28. * abs(length(q) - .3)) / pow(1.4, float(i));
    }
    vec2 flow = vec2(sin(q.y * 8. + iTime), cos(q.x * 7. - iTime)) * (.008 + .018 * m);
    vec2 uv = fract(q / vec2(A, 1) + .5 + flow);
    float ca = .005 + .026 * t;
    vec3 c = vec3(texture(samp, uv + ca).r, texture(samp, uv).g, texture(samp, uv - ca).b) *
             (.42 + .62 * P(length(q) * .4));
    float rays = pow(max(cos(an * seg + r * 20. - iTime), 0.), 20.) * exp(-r * 1.7);
    float stars = step(.992, H(floor((p + 2.) * 110.)));
    c += P(k / w + r - iTime * .07) * (glow * (.5 + 1.5 * a) + rays * (.35 + 2. * b)) +
         P(iTime * .1 + r) * stars * (.35 + 2. * a);
    c *= .9 + .34 * amp_smooth;
    c = mix(c, 1. - c, smoothstep(.94, 1., amp_peak));
    color = vec4(1. - exp(-max(c, 0.) * 1.34), 1);
}
