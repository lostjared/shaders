#version 330 core
#ifndef SIZE
#define SIZE 8
#endif
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform sampler2D textures[SIZE];
uniform vec2 iResolution;
uniform float time_f;
mat2 rot(float a) { return mat2(cos(a), -sin(a), sin(a), cos(a)); }
vec2 mir(vec2 u) { return 1.0 - abs(mod(u, 2.0) - 1.0); }
vec3 pal(float x) { return .5 + .5 * cos(6.28318 * (x + vec3(0, .28, .62))); }
void main() {
    vec2 p = (tc - .5) * vec2(iResolution.x / iResolution.y, 1.);
    float t = time_f;
    float r = length(p), a = atan(p.y, p.x);
    vec3 acc = texture(samp, tc).rgb * .55;
    float w = .55;
    for (int i = 0; i < SIZE; i++) {
        float n = float(i + 1), q = n / float(SIZE);
        vec2 z = rot(sin(a) * .18 + sin(t * .3 + n) * .06) * p;
        float twist = 1.2 * sin(t * .7 - r * 7.0 + n * .8);
        z = rot(twist * q) * z;
        z += .035 * q * vec2(sin(a * 9. - t * 1.4 + n), cos(a * 7. + t));
        vec3 h = texture(textures[i], mir(z / vec2(iResolution.x / iResolution.y, 1.) + .5)).rgb;
        float ww = pow(.82, n) * (1. - .25 * q);
        acc += h * pal(a / 6.28318 + t * .04 + n * .09) * ww;
        w += ww;
    }
    vec3 c = acc / w;
    c += .16 * pal(a / 6.28318 + t * .08) * exp(-r * 5.);
    color = vec4(clamp(c / (1. + c), 0., 1.), 1.);
}
