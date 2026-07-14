#version 330 core
// Spiral stellar forge submerged beneath rolling spectral caustics.
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform sampler1D spectrum;
uniform float iTime, amp_peak, amp_smooth;
uniform vec2 iResolution;
const float T = 6.28318530718;
float H(vec2 p) {
    return fract(sin(dot(p, vec2(27.1, 113.5))) * 43758.5);
}
vec3 P(float x) {
    return .5 + .5 * cos(T * (x + vec3(.56, .22, .02)));
}
void main() {
    float b = texture(spectrum, .03).r, m = texture(spectrum, .22).r, t = texture(spectrum, .61).r,
          a = texture(spectrum, .88).r;
    float A = iResolution.x / iResolution.y;
    vec2 p = (tc - .5) * vec2(A, 1);
    float r = length(p) + .01, an = atan(p.y, p.x);
    float wave = sin(p.x * 14. + sin(p.y * 7. - iTime) * 2.) + sin(p.y * 17. - iTime * 1.3);
    vec2 uv = tc + vec2(wave, sin(wave * T)) * (.006 + .012 * m);
    float ca = .004 + .022 * t;
    vec3 c = vec3(texture(samp, uv + ca).r, texture(samp, uv).g, texture(samp, uv - ca).b) *
             vec3(.45, .7, 1.);
    float arm = pow(.5 + .5 * cos(an * 5. - log(r) * 7. + iTime * (.7 + b)), 14.) * exp(-r * 2.);
    float caust = pow(max(wave * .25 + .5, 0.), 8.);
    float stars = step(.991, H(floor((p + 2.) * 100.)));
    c += P(an / T + r - iTime * .08) * arm * (.7 + 2.5 * b) +
         vec3(.2, .7, 1) * caust * (.15 + a * .6) + P(iTime * .1) * stars * (.4 + 2. * a);
    c *= .9 + .3 * amp_smooth;
    c = mix(c, 1. - c, smoothstep(.95, 1., amp_peak));
    color = vec4(1. - exp(-max(c, 0.) * 1.3), 1);
}
