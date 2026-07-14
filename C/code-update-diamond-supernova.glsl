#version 330 core
// Faceted diamond implosion opening into an audio-reactive supernova.
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform sampler1D spectrum;
uniform float iTime, amp_peak, amp_smooth;
uniform vec2 iResolution;
const float T = 6.28318530718;
mat2 R(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c);
}
vec3 P(float x) {
    return .5 + .5 * cos(T * (x + vec3(.05, .32, .7)));
}
void main() {
    float b = texture(spectrum, .03).r, m = texture(spectrum, .23).r, t = texture(spectrum, .59).r,
          a = texture(spectrum, .86).r;
    float A = iResolution.x / iResolution.y;
    vec2 p = (tc - .5) * vec2(A, 1);
    float r = length(p), an = atan(p.y, p.x);
    vec2 q = p;
    for (int i = 0; i < 5; i++) {
        q = abs(q);
        if (q.x < q.y)
            q = q.yx;
        q = q * 1.34 - vec2(.31, .19);
        q *= R(.34 + float(i) * .23 + iTime * .025);
    }
    vec2 uv = fract(q / vec2(A, 1) + .5);
    float ca = .006 + .025 * t;
    vec3 c = vec3(texture(samp, uv + ca).r, texture(samp, uv).g, texture(samp, uv - ca).b);
    float facet = exp(-18. * abs(abs(q.x) - abs(q.y)));
    float burst =
        pow(max(cos(an * 18. + sin(an * 5.) * 2. - iTime * 2.), 0.), 20.) * exp(-r * (2. + b));
    float shell = exp(-abs(r - (.22 + .08 * sin(iTime * 1.4) - .05 * b)) * 70.);
    c *= .55 + .7 * P(length(q) * .5 + iTime * .04);
    c += P(an / T + r - iTime * .08) *
         (facet * (.45 + m) + burst * (.8 + 2. * a) + shell * (.7 + 2.5 * b));
    c *= .9 + .3 * amp_smooth;
    c = mix(c, 1. - c, smoothstep(.94, 1., amp_peak));
    color = vec4(1. - exp(-max(c, 0.) * 1.25), 1);
}
