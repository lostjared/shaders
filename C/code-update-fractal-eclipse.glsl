#version 330 core
// Recursive solar eclipse with folded corona, prominences, and gravitational shimmer.
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
vec3 P(float x) {
    return .5 + .5 * cos(T * (x + vec3(.01, .17, .48)));
}
float corona(vec2 p) {
    float v = 0.;
    for (int i = 0; i < 5; i++) {
        p = abs(p) * 1.55 - vec2(.42, .31);
        p *= R(.35 + float(i) * .5);
        v += exp(-10. * abs(length(p) - .5)) / pow(1.5, float(i));
    }
    return v;
}
void main() {
    float b = texture(spectrum, .03).r, m = texture(spectrum, .23).r, t = texture(spectrum, .61).r,
          a = texture(spectrum, .88).r;
    float A = iResolution.x / iResolution.y;
    vec2 p = (tc - .5) * vec2(A, 1);
    float r = length(p), an = atan(p.y, p.x), co = corona(p * (1.5 + b * .2));
    vec2 uv = tc + normalize(p + vec2(1e-4)) * sin(r * 40. - iTime * 2.) * (.004 + .016 * m);
    float ca = .003 + .018 * t;
    vec3 c = vec3(texture(samp, uv + ca).r, texture(samp, uv).g, texture(samp, uv - ca).b) * .28;
    float rim = exp(-abs(r - (.24 + .025 * b)) * 85.);
    float rays = pow(max(cos(an * 19. + co * 3. - iTime), 0.), 20.) * exp(-r * 2.);
    c += P(an / T + r - iTime * .07) *
         (rim * (1. + 3. * b) + co * (.25 + a) + rays * (.45 + 2. * a));
    c *= smoothstep(.19, .245, r);
    c += vec3(.025, .015, .04) * (1. - smoothstep(.05, .21, r));
    c *= .9 + .32 * amp_smooth;
    c = mix(c, 1. - c, smoothstep(.95, 1., amp_peak));
    color = vec4(1. - exp(-max(c, 0.) * 1.3), 1);
}
