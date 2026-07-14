#version 330 core
// Deep log-polar tunnel with braided spectrum rails and prismatic motion blur.
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform sampler1D spectrum;
uniform float iTime, amp_peak, amp_smooth;
uniform vec2 iResolution;
const float T = 6.28318530718;
vec3 P(float x) {
    return .5 + .5 * cos(T * (x + vec3(.0, .34, .68)));
}
void main() {
    float b = texture(spectrum, .03).r, m = texture(spectrum, .23).r, t = texture(spectrum, .6).r,
          a = texture(spectrum, .88).r;
    float A = iResolution.x / iResolution.y;
    vec2 p = (tc - .5) * vec2(A, 1);
    float r = length(p) + .008, an = atan(p.y, p.x);
    float z = log(r) * 1.25 + iTime * (.5 + b);
    float twist = an + z * (.8 + m * 1.4) + sin(z * 2.) * .2;
    vec2 uv = fract(vec2(twist / T * 3., z * .22));
    float ca = .006 + .025 * t;
    vec3 c = vec3(texture(samp, uv + vec2(ca, 0)).r, texture(samp, uv).g,
                  texture(samp, uv - vec2(ca, 0)).b);
    float rail = 0.;
    for (int i = 0; i < 4; i++) {
        float fi = float(i);
        rail += pow(.5 + .5 * cos(twist * (6. + fi * 2.) + z * (2. - fi * .25) + fi), 18.) / 4.;
    }
    float ring = pow(.5 + .5 * cos(z * 12. - iTime * 2.), 16.);
    c *= .52 + .62 * P(z * .06 + twist / T);
    c += P(twist / T + z * .08 - iTime * .05) * (rail * (.8 + 2. * a) + ring * (.2 + b));
    c *= smoothstep(.025, .16, r);
    c *= .9 + .32 * amp_smooth;
    c = mix(c, 1. - c, smoothstep(.96, 1., amp_peak));
    color = vec4(1. - exp(-max(c, 0.) * 1.3), 1);
}
