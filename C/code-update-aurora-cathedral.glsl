#version 330 core
// Polar rose vault with layered aurora glass and spectral edge light.
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform sampler1D spectrum;
uniform float iTime, amp_peak, amp_smooth;
uniform vec2 iResolution;
const float TAU = 6.28318530718;
mat2 R(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c);
}
float h(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
float n(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3. - 2. * f);
    return mix(mix(h(i), h(i + vec2(1, 0)), f.x), mix(h(i + vec2(0, 1)), h(i + 1.), f.x), f.y);
}
vec3 pal(float t) {
    return .48 + .52 * cos(TAU * (t + vec3(.02, .29, .62)));
}
void main() {
    float b = texture(spectrum, .035).r, m = texture(spectrum, .22).r, t = texture(spectrum, .58).r,
          a = texture(spectrum, .84).r;
    float asp = iResolution.x / iResolution.y;
    vec2 p = (tc - .5) * vec2(asp, 1);
    float r = length(p), an = atan(p.y, p.x);
    float seg = 8. + floor(b * 6.);
    float w = TAU / seg;
    float k = abs(mod(an + w * .5, w) - w * .5);
    vec2 q = vec2(cos(k), sin(k)) * r;
    q *= R(.18 * sin(iTime * .31) + m * .35);
    for (int i = 0; i < 3; i++) {
        q = abs(q) * 1.42 - vec2(.36, .22);
        q *= R(.42 + float(i) * .31 + iTime * .035);
    }
    float veil = n(vec2(an * 2.6 - iTime * .18, r * 9. - iTime * (.7 + b)));
    vec2 uv = fract(q / vec2(asp, 1) + .5 + vec2(0, veil - .5) * .025);
    float ca = .004 + .024 * t;
    vec3 c = vec3(texture(samp, uv + vec2(ca, 0)).r, texture(samp, uv).g,
                  texture(samp, uv - vec2(ca, 0)).b);
    float rose = pow(max(cos(k * seg * 2. - r * 11. + iTime), 0.), 12.) * exp(-r * 1.6);
    float glass = smoothstep(.48, .52, sin(r * 28. + k * 14. - iTime * 1.2));
    c = mix(c, c * pal(an / TAU + r * .7 + iTime * .05), .36 + glass * .3) +
        pal(veil + iTime * .08) * rose * (.7 + 2. * a);
    c *= .9 + .25 * amp_smooth;
    c = mix(c, 1. - c, smoothstep(.94, 1., amp_peak));
    c = 1. - exp(-max(c, 0.) * 1.25);
    color = vec4(c, 1);
}
