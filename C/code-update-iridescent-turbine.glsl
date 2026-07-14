#version 330 core
// Counter-rotating prismatic turbine blades with metallic interference highlights.
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform sampler1D spectrum;
uniform float iTime, amp_peak, amp_smooth;
uniform vec2 iResolution;
const float T = 6.28318530718;
vec3 P(float x) {
    return .5 + .5 * cos(T * (x + vec3(.02, .39, .73)));
}
void main() {
    float b = texture(spectrum, .03).r, m = texture(spectrum, .24).r, t = texture(spectrum, .62).r,
          a = texture(spectrum, .9).r;
    float A = iResolution.x / iResolution.y;
    vec2 p = (tc - .5) * vec2(A, 1);
    float r = length(p) + .001, an = atan(p.y, p.x), blade = 14. + floor(b * 6.);
    float twist = an * blade + log(r) * 5. - iTime * (1. + b * 2.);
    float vane = .5 + .5 * sin(twist);
    vec2 q = vec2(cos(an + vane * .35), sin(an + vane * .35)) * r * (1. + .18 * m * vane);
    vec2 uv = fract(q / vec2(A, 1) + .5);
    vec2 tanv = normalize(vec2(-p.y, p.x));
    float ca = .004 + .026 * t;
    vec3 c =
        vec3(texture(samp, uv + tanv * ca).r, texture(samp, uv).g, texture(samp, uv - tanv * ca).b);
    float edge = pow(1. - abs(vane - .5) * 2., 20.), hub = exp(-r * 18.);
    vec3 metal = mix(vec3(.08, .11, .16), P(vane + r - iTime * .04), .72);
    c = mix(c, metal, .28 + .25 * vane);
    c += P(twist / T + r) * (edge * (.55 + 1.8 * a) + hub * (.5 + 2. * b));
    c *= .9 + .32 * amp_smooth;
    c = mix(c, 1. - c, smoothstep(.95, 1., amp_peak));
    color = vec4(1. - exp(-max(c, 0.) * 1.25), 1);
}
