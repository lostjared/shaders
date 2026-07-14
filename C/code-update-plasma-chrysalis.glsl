#version 330 core
// Symmetric plasma cocoon with wing membranes and hot filament veins.
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform sampler1D spectrum;
uniform float iTime, amp_peak, amp_smooth;
uniform vec2 iResolution;
const float T = 6.28318530718;
vec3 P(float x) {
    return .5 + .5 * cos(T * (x + vec3(.08, .4, .72)));
}
float F(vec2 p) {
    float v = 0.;
    for (int i = 0; i < 5; i++) {
        p = abs(p) * 1.45 - vec2(.48, .25);
        p += .12 * sin(p.yx * 4. + iTime * .35 + float(i));
        v += sin(length(p) * 12. - iTime + float(i)) / pow(1.5, float(i));
    }
    return v;
}
void main() {
    float b = texture(spectrum, .03).r, m = texture(spectrum, .22).r, t = texture(spectrum, .62).r,
          a = texture(spectrum, .88).r;
    float A = iResolution.x / iResolution.y;
    vec2 p = (tc - .5) * vec2(A, 1);
    p.x = abs(p.x);
    float f = F(p * (1.3 + b * .2));
    float wing = smoothstep(.62, .1, length(p * vec2(.75, 1.2))) * smoothstep(.02, .16, p.x);
    vec2 uv = vec2(abs(tc.x - .5) + .5, tc.y) + vec2(sin(f), cos(f)) * (.008 + .02 * m);
    float ca = .004 + .018 * t;
    vec3 c = vec3(texture(samp, uv + ca).r, texture(samp, uv).g, texture(samp, uv - ca).b);
    float veins = pow(.5 + .5 * sin(f * 4. + length(p) * 28.), 14.) * wing;
    c *= .45 + .62 * P(f * .1 + iTime * .025);
    c += P(f * .08 + p.y - iTime * .07) * veins * (.6 + 2. * a);
    c += P(iTime * .1) * exp(-abs(p.x - .04) * 45.) * wing * (.5 + 2. * b);
    c *= .9 + .3 * amp_smooth;
    c = mix(c, 1. - c, smoothstep(.95, 1., amp_peak));
    color = vec4(1. - exp(-max(c, 0.) * 1.3), 1);
}
