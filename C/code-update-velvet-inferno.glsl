#version 330 core
// Slow folded flame with velvety shadows, ember threads, and jewel-tone heat.
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform sampler1D spectrum;
uniform float iTime, amp_peak, amp_smooth;
uniform vec2 iResolution;
const float T = 6.28318530718;
float H(vec2 p) {
    return fract(sin(dot(p, vec2(91.7, 233.1))) * 43758.5);
}
float N(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3. - 2. * f);
    return mix(mix(H(i), H(i + vec2(1, 0)), f.x), mix(H(i + vec2(0, 1)), H(i + 1.), f.x), f.y);
}
float F(vec2 p) {
    float f = 0., w = .5;
    for (int i = 0; i < 5; i++) {
        f += w * N(p);
        p = mat2(1.6, -1.2, 1.2, 1.6) * p + 3.1;
        w *= .5;
    }
    return f;
}
vec3 P(float x) {
    return .45 + .55 * cos(T * (x + vec3(.02, .12, .48)));
}
void main() {
    float b = texture(spectrum, .03).r, m = texture(spectrum, .22).r, t = texture(spectrum, .6).r,
          a = texture(spectrum, .87).r;
    float A = iResolution.x / iResolution.y;
    vec2 p = (tc - .5) * vec2(A, 1);
    float flame = F(vec2(p.x * 3. + sin(p.y * 5.) * .4, p.y * 3. - iTime * (.5 + b)));
    float shape = smoothstep(.72, .15, abs(p.x) * (1.2 + p.y) - flame * .28 + .08);
    vec2 uv = tc + vec2(sin(flame * T), -flame) * (.012 + .018 * m);
    float ca = .004 + .02 * t;
    vec3 c = vec3(texture(samp, uv + ca).r, texture(samp, uv).g, texture(samp, uv - ca).b) *
             (.35 + .45 * shape);
    float thread = pow(.5 + .5 * sin(flame * 24. - p.y * 18. + iTime * 2.), 14.) * shape;
    c += P(flame * .35 - p.y * .4 + iTime * .03) *
         (shape * (.28 + b * .4) + thread * (.55 + 1.5 * a));
    c *= .9 + .32 * amp_smooth;
    c = mix(c, 1. - c, smoothstep(.96, 1., amp_peak));
    color = vec4(1. - exp(-max(c, 0.) * 1.35), 1);
}
