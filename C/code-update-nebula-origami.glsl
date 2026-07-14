#version 330 core
// Recursive paper folds drifting through a luminous spectral nebula.
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
float H(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5);
}
vec3 P(float x) {
    return .5 + .5 * cos(T * (x + vec3(.6, .25, .02)));
}
void main() {
    float b = texture(spectrum, .03).r, m = texture(spectrum, .21).r, t = texture(spectrum, .6).r,
          a = texture(spectrum, .87).r;
    float A = iResolution.x / iResolution.y;
    vec2 p = (tc - .5) * vec2(A, 1), q = p;
    q *= R(iTime * .05);
    float crease = 0.;
    for (int i = 0; i < 5; i++) {
        q = abs(q);
        if (q.x < q.y)
            q = q.yx;
        q = q * 1.36 - vec2(.37, .24);
        q *= R(.28 + float(i) * .41 + m * .04);
        crease += exp(-70. * min(abs(q.x), abs(q.y))) / pow(1.5, float(i));
    }
    float dust = H(floor((p + 2.) * 90.));
    vec2 uv = fract(q / vec2(A, 1) + .5);
    float ca = .004 + .02 * t;
    vec3 c = vec3(texture(samp, uv + ca).r, texture(samp, uv).g, texture(samp, uv - ca).b) *
             (.42 + .62 * P(length(q) * .25));
    float stars = step(.992, dust) * (.5 + .5 * sin(iTime * 2. + dust * 30.));
    c += P(length(q) * .4 + iTime * .04) * crease * (.4 + 1.5 * a) +
         P(atan(p.y, p.x) / T) * stars * (.5 + 2. * a);
    c *= .9 + .3 * amp_smooth;
    c = mix(c, 1. - c, smoothstep(.96, 1., amp_peak));
    color = vec4(1. - exp(-max(c, 0.) * 1.28), 1);
}
