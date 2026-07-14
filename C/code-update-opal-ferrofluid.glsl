#version 330 core
// Flowing magnetic cells, opalescent ridges, and liquid lens sampling.
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
float field(vec2 p, float tm) {
    float v = 0.;
    for (int i = 0; i < 5; i++) {
        p = abs(p) / clamp(dot(p, p), .22, 2.4) - .72;
        p *= R(.47 + float(i) * .17);
        v += exp(-9. * abs(length(p) - .72));
        p += .08 * sin(tm + float(i) * 2.1);
    }
    return v / 5.;
}
vec3 pal(float x) {
    return .52 + .48 * cos(TAU * (x + vec3(.03, .36, .67)));
}
void main() {
    float b = texture(spectrum, .04).r, m = texture(spectrum, .24).r, t = texture(spectrum, .62).r,
          a = texture(spectrum, .86).r;
    float asp = iResolution.x / iResolution.y;
    vec2 p = (tc - .5) * vec2(asp, 1);
    float tm = iTime * .22;
    p *= R(.12 * sin(iTime * .4));
    float f = field(p * (1.7 + b * .3), tm);
    float e = .004;
    vec2 g = vec2(field(p + vec2(e, 0), tm) - field(p - vec2(e, 0), tm),
                  field(p + vec2(0, e), tm) - field(p - vec2(0, e), tm)) /
             (2. * e);
    vec2 uv = tc + g * (.012 + .025 * m);
    float ca = .003 + .018 * t;
    vec3 c = vec3(texture(samp, uv + g * ca).r, texture(samp, uv).g, texture(samp, uv - g * ca).b);
    float ridge = pow(clamp(f * 1.7, 0., 1.), 2.);
    vec3 opal = pal(f * .8 + length(p) * .4 - iTime * .06 + dot(g, vec2(.2)));
    c = mix(c, c * opal, .42) + opal * ridge * (.45 + 1.5 * a);
    c += pow(max(dot(normalize(vec3(g, 1)), normalize(vec3(-.4, .6, 1))), 0.), 18.) * (.5 + b);
    c *= .88 + .3 * amp_smooth;
    c = mix(c, c.gbr, .18 * m);
    c = mix(c, 1. - c, smoothstep(.95, 1., amp_peak));
    color = vec4(1. - exp(-max(c, 0.) * 1.3), 1);
}
