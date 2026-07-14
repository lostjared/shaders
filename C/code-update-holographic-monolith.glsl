#version 330 core
// Impossible mirrored monolith with scanline diffraction and spectral aura.
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform sampler1D spectrum;
uniform float iTime, amp_peak, amp_smooth;
uniform vec2 iResolution;
const float T = 6.28318530718;
vec3 P(float x) {
    return .5 + .5 * cos(T * (x + vec3(.0, .3, .65)));
}
void main() {
    float b = texture(spectrum, .03).r, m = texture(spectrum, .2).r, t = texture(spectrum, .6).r,
          a = texture(spectrum, .88).r;
    float A = iResolution.x / iResolution.y;
    vec2 p = (tc - .5) * vec2(A, 1);
    float y = p.y + .12 * sin(iTime * .4);
    float perspective = 1. / (1.3 - y * .55);
    vec2 q = vec2(abs(p.x) * perspective, y);
    float box = max(q.x - .22, abs(q.y) - .42);
    float edge = exp(-abs(box) * 90.);
    float inside = 1. - smoothstep(-.01, .01, box);
    vec2 uv = fract(vec2(q.x * 2.2 + .5, q.y * perspective + .5) +
                    vec2(sin(q.y * 20. + iTime), 0) * .012 * m);
    float ca = .004 + .024 * t;
    vec3 c = vec3(texture(samp, uv + vec2(ca, 0)).r, texture(samp, uv).g,
                  texture(samp, uv - vec2(ca, 0)).b);
    float scan = pow(.5 + .5 * sin(q.y * (140. + a * 40.) - iTime * 5.), 12.);
    float aura = exp(-max(box, 0.) * 12.) * smoothstep(.35, 0., max(box, 0.));
    c *= inside * (.5 + .62 * P(q.y * .3 + iTime * .03));
    c += P(q.y * .35 - iTime * .08) *
         (edge * (.8 + 2. * b) + scan * inside * (.15 + a * .5) + aura * .18);
    c *= .9 + .3 * amp_smooth;
    c = mix(c, 1. - c, smoothstep(.95, 1., amp_peak));
    color = vec4(1. - exp(-max(c, 0.) * 1.28), 1);
}
