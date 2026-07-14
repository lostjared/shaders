#version 330 core
// Reflective liquid-metal rose with animated normal lighting and spectral oil sheen.
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform sampler1D spectrum;
uniform float iTime, amp_peak, amp_smooth;
uniform vec2 iResolution;
const float T = 6.28318530718;
vec3 P(float x) {
    return .48 + .52 * cos(T * (x + vec3(.04, .24, .58)));
}
float F(vec2 p, float b) {
    float r = length(p), a = atan(p.y, p.x);
    return sin(r * 31. - iTime * 1.7 + cos(a * (7. + floor(b * 4.))) * 3.) * .5 + .5;
}
void main() {
    float b = texture(spectrum, .035).r, m = texture(spectrum, .22).r, t = texture(spectrum, .58).r,
          a = texture(spectrum, .86).r;
    float A = iResolution.x / iResolution.y;
    vec2 p = (tc - .5) * vec2(A, 1);
    float e = .0025, f = F(p, b);
    vec2 g = vec2(F(p + vec2(e, 0), b) - F(p - vec2(e, 0), b),
                  F(p + vec2(0, e), b) - F(p - vec2(0, e), b)) /
             (2. * e);
    vec3 N = normalize(vec3(-g * .07, 1));
    float sp = pow(max(dot(reflect(normalize(vec3(.4, -.5, -1)), N), vec3(0, 0, 1)), 0.), 24.);
    vec2 uv = tc + g * (.002 + .006 * m);
    float ca = .002 + .012 * t;
    vec3 c = vec3(texture(samp, uv + g * ca).r, texture(samp, uv).g, texture(samp, uv - g * ca).b);
    vec3 metal =
        mix(vec3(.12, .15, .2), vec3(.85, .9, 1), max(dot(N, normalize(vec3(-.4, .6, 1))), 0.));
    c = mix(c, metal, .42 + .2 * f);
    c += P(f + length(p) * .5 + iTime * .03) * pow(f, 7.) * (.4 + a) + sp * (.8 + 2. * b);
    c *= .9 + .3 * amp_smooth;
    c = mix(c, 1. - c, smoothstep(.95, 1., amp_peak));
    color = vec4(1. - exp(-max(c, 0.) * 1.2), 1);
}
