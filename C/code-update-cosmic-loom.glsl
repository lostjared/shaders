#version 330 core
// Interwoven luminous ribbons forming a rotating celestial tapestry.
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
    return .5 + .5 * cos(T * (x + vec3(.0, .37, .7)));
}
void main() {
    float b = texture(spectrum, .03).r, m = texture(spectrum, .2).r, t = texture(spectrum, .6).r,
          a = texture(spectrum, .87).r;
    float A = iResolution.x / iResolution.y;
    vec2 p = (tc - .5) * vec2(A, 1);
    p *= R(iTime * .07);
    float warp = .08 * sin(p.yx * 6. + iTime * vec2(.7, -.5)).x * m;
    vec2 q = p + warp;
    float wx = sin(q.x * (18. + b * 9.) + sin(q.y * 7. - iTime) * 2.),
          wy = sin(q.y * (21. + m * 8.) + sin(q.x * 6. + iTime * .8) * 2.);
    float loom = pow(1. - abs(wx), 18.) + pow(1. - abs(wy), 18.);
    float over = step(0., sin((floor((q.x + 2.) * 9.) + floor((q.y + 2.) * 9.)) * 1.57));
    vec2 uv = tc + vec2(wy, wx) * (.008 + .018 * t);
    vec3 c = texture(samp, uv).rgb * (.52 + .56 * P(q.x * .25 - q.y * .2));
    vec3 thread = mix(P(q.x + iTime * .04), P(q.y - iTime * .05), over);
    c += thread * loom * (.55 + 1.5 * a);
    float star = pow(max(cos(atan(p.y, p.x) * 14. - length(p) * 30. + iTime), 0.), 32.) *
                 exp(-length(p) * 2.);
    c += P(iTime * .08) * star * (.35 + 2. * b);
    c *= .9 + .32 * amp_smooth;
    c = mix(c, 1. - c, smoothstep(.96, 1., amp_peak));
    color = vec4(1. - exp(-max(c, 0.) * 1.25), 1);
}
