#version 330 core
// Animated coral branches with electric polyps and deep-ocean iridescence.
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform sampler1D spectrum;
uniform float iTime, amp_peak, amp_smooth;
uniform vec2 iResolution;
const float T = 6.28318530718;
vec3 P(float x) {
    return .5 + .5 * cos(T * (x + vec3(.55, .2, .88)));
}
float H(vec2 p) {
    return fract(sin(dot(p, vec2(27.1, 91.7))) * 43758.5);
}
float F(vec2 p) {
    float v = 0.;
    for (int i = 0; i < 6; i++) {
        p = abs(p) * 1.42 - vec2(.38, .28);
        p += .08 * sin(p.yx * 5. + iTime * .4 + float(i));
        v += exp(-16. * abs(p.x + sin(p.y * 4.) * .08)) / pow(1.35, float(i));
    }
    return v;
}
void main() {
    float b = texture(spectrum, .035).r, m = texture(spectrum, .22).r, t = texture(spectrum, .64).r,
          a = texture(spectrum, .9).r;
    float A = iResolution.x / iResolution.y;
    vec2 p = (tc - .5) * vec2(A, 1);
    p.y += .28;
    float f = F(p * (1.2 + b * .25));
    vec2 uv = tc + vec2(sin(p.y * 12. + iTime), cos(p.x * 10. - iTime)) * .012 * m;
    vec3 c = texture(samp, uv).rgb * (.4 + .58 * P(p.y * .3 + iTime * .02));
    float polyp =
        step(.975, H(floor((p + 2.) * 35.))) * (.5 + .5 * sin(iTime * 5. + H(floor(p * 35.)) * T));
    c += P(f * .2 + p.y - iTime * .06) * f * (.65 + 1.7 * t) +
         P(iTime * .1 + length(p)) * polyp * (.6 + 2. * a);
    c += vec3(.03, .12, .2) * (1. - smoothstep(-.5, .5, p.y));
    c *= .9 + .32 * amp_smooth;
    c = mix(c, 1. - c, smoothstep(.95, 1., amp_peak));
    color = vec4(1. - exp(-max(c, 0.) * 1.25), 1);
}
