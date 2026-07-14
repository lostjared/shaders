#version 330 core
// Concentric orbital echoes with dispersion and luminous interference rings.
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform sampler1D spectrum;
uniform float iTime, amp_peak, amp_smooth;
uniform vec2 iResolution;
const float TAU = 6.28318530718;
mat2 R(float x) {
    float c = cos(x), s = sin(x);
    return mat2(c, -s, s, c);
}
vec3 pal(float x) {
    return .5 + .5 * cos(TAU * (x + vec3(.0, .31, .63)));
}
void main() {
    float b = texture(spectrum, .025).r, m = texture(spectrum, .19).r, t = texture(spectrum, .57).r,
          a = texture(spectrum, .83).r;
    float asp = iResolution.x / iResolution.y;
    vec2 p = (tc - .5) * vec2(asp, 1);
    float r = length(p), an = atan(p.y, p.x);
    vec3 acc = vec3(0);
    float ws = 0.;
    for (int i = 0; i < 7; i++) {
        float fi = float(i), age = fi / 6.;
        vec2 q = p * R(iTime * (.045 + age * .055) + fi * .62 + b * .3);
        q *= 1. + age * (.08 + .18 * b);
        q += normalize(p + vec2(1e-4)) * sin(r * 24. - iTime * 2. + fi) * .008 * m;
        vec2 uv = q / vec2(asp, 1) + .5;
        float ca = age * (.004 + .024 * t);
        vec3 s = vec3(texture(samp, uv + vec2(ca, 0)).r, texture(samp, uv).g,
                      texture(samp, uv - vec2(ca, 0)).b);
        float w = pow(.78, fi);
        // Keep the tint periodic across atan's -PI/PI boundary.
        float angularPhase = .06 * cos(an) + .04 * sin(an * 2.);
        acc += s * pal(age * .28 + angularPhase + iTime * .025) * w;
        ws += w;
    }
    vec3 c = acc / ws;
    float rings =
        pow(.5 + .5 * cos(r * (54. + m * 20.) - iTime * (2. + b * 3.) + sin(an * 5.) * 2.), 14.);
    float orbit =
        pow(max(cos(an * 6. - iTime + r * 8.), 0.), 18.) * smoothstep(.48, .12, abs(r - .34));
    c += pal(r * 1.5 - iTime * .09) * (rings * (.24 + a * .8) + orbit * (.4 + b));
    c *= .94 + .3 * amp_smooth;
    c = mix(c, 1. - c, smoothstep(.96, 1., amp_peak));
    color = vec4(1. - exp(-max(c, 0.) * 1.2), 1);
}
