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
mat2 R(float a) { return mat2(cos(a), -sin(a), sin(a), cos(a)); }
vec2 mir(vec2 u) { return 1. - abs(mod(u, 2.) - 1.); }
vec3 P(float x) { return .5 + .5 * cos(6.28318 * (x + vec3(0, .33, .67))); }
void main() {
    vec2 p = (tc - .5) * vec2(iResolution.x / iResolution.y, 1.);
    float t = time_f, sector = 6.28318 / 9.;
    vec3 a = texture(samp, tc).rgb * .5;
    float w = .5;
    for (int i = 0; i < SIZE; i++) {
        float n = float(i + 1), q = n / float(SIZE), ang = atan(p.y, p.x) + t * .08 * q;
        ang = abs(mod(ang, sector) - sector * .5);
        vec2 z = vec2(cos(ang), sin(ang)) * length(p);
        z = R(.25 * sin(t * .5 + n)) * z;
        z *= 1. + .1 * sin(length(z) * 18. - t + n);
        vec3 h = texture(textures[i], mir(z / vec2(iResolution.x / iResolution.y, 1.) + .5)).rgb;
        float k = pow(.84, n);
        a += h * P(q + length(p) * .5 + t * .02) * k;
        w += k;
    }
    vec3 c = a / w;
    color = vec4(clamp(c / (1. + c), 0., 1.), 1.);
}
