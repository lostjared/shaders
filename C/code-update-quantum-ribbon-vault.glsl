#version 330 core
// Braided quantum ribbons folded into a mirrored, depth-shifting vault.
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
    return .5 + .5 * cos(T * (x + vec3(.0, .28, .66)));
}
void main() {
    float b = texture(spectrum, .03).r, m = texture(spectrum, .2).r, t = texture(spectrum, .59).r,
          a = texture(spectrum, .87).r;
    float A = iResolution.x / iResolution.y;
    vec2 p = (tc - .5) * vec2(A, 1), q = p;
    q *= R(iTime * .09);
    q = abs(q);
    if (q.x < q.y)
        q = q.yx;
    float ribbons = 0.;
    for (int i = 0; i < 5; i++) {
        float fi = float(i);
        float strand =
            sin(q.x * (15. + fi * 3.) + sin(q.y * (7. + fi)) * 2. + iTime * (.7 - fi * .08));
        ribbons += pow(1. - abs(strand), 18.) / pow(1.35, fi);
        q = abs(q * 1.32 - vec2(.31, .22));
        q *= R(.32 + fi * .27);
    }
    vec2 uv = fract(q / vec2(A, 1) + .5);
    float ca = .004 + .023 * t;
    vec3 c = vec3(texture(samp, uv + ca).r, texture(samp, uv).g, texture(samp, uv - ca).b) *
             (.46 + .58 * P(length(q) * .3));
    c += P(ribbons * .15 + atan(p.y, p.x) / T - iTime * .06) * ribbons * (.45 + 1.7 * a);
    c += P(iTime * .08) * exp(-length(p) * 15.) * (.4 + 2. * b);
    c *= .9 + .3 * amp_smooth;
    c = mix(c, 1. - c, smoothstep(.96, 1., amp_peak));
    color = vec4(1. - exp(-max(c, 0.) * 1.26), 1);
}
