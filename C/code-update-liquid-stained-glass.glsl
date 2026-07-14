#version 330 core
// Molten stained-glass cells with lead outlines and chromatic refraction.
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform sampler1D spectrum;
uniform float iTime, amp_peak, amp_smooth;
uniform vec2 iResolution;
const float T = 6.28318530718;
float H(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.545);
}
vec3 P(float x) {
    return .5 + .5 * cos(T * (x + vec3(.0, .27, .61)));
}
float V(vec2 p, out vec2 id) {
    vec2 g = floor(p), f = fract(p);
    float d = 9.;
    for (int y = -1; y <= 1; y++)
        for (int x = -1; x <= 1; x++) {
            vec2 o = vec2(x, y), z = o + vec2(H(g + o), H(g + o + 19.3));
            z = .5 + .42 * sin(iTime * .35 + T * z);
            float nd = length(f - o - z);
            if (nd < d) {
                d = nd;
                id = g + o;
            }
        }
    return d;
}
void main() {
    float b = texture(spectrum, .04).r, m = texture(spectrum, .21).r, t = texture(spectrum, .61).r,
          a = texture(spectrum, .87).r;
    float A = iResolution.x / iResolution.y;
    vec2 p = (tc - .5) * vec2(A, 1), id;
    float d = V(p * (7. + b * 2.), id), e = .004;
    vec2 z;
    vec2 g = vec2(V((p + vec2(e, 0)) * (7. + b * 2.), z) - V((p - vec2(e, 0)) * (7. + b * 2.), z),
                  V((p + vec2(0, e)) * (7. + b * 2.), z) - V((p - vec2(0, e)) * (7. + b * 2.), z));
    vec2 uv = tc + g * (.025 + .03 * m);
    float ca = .005 + .02 * t;
    vec3 c = vec3(texture(samp, uv + g * ca).r, texture(samp, uv).g, texture(samp, uv - g * ca).b);
    vec3 glass = P(H(id) * .7 + iTime * .025 + d * .2);
    float lead = 1. - smoothstep(.035, .09, d);
    c = mix(c, c * glass, .62);
    c += glass * pow(max(0., .55 - d), 7.) * (2. + a * 2.);
    c *= 1. - lead * .82;
    c += lead * vec3(.04, .06, .09);
    c *= .9 + .3 * amp_smooth;
    c = mix(c, 1. - c, smoothstep(.96, 1., amp_peak));
    color = vec4(1. - exp(-max(c, 0.) * 1.3), 1);
}
