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
vec2 mir(vec2 u) { return 1. - abs(mod(u, 2.) - 1.); }
vec3 P(float x) { return .5 + .5 * cos(6.28318 * (x + vec3(.02, .31, .66))); }
void main() {
    vec2 p = (tc - .5) * vec2(iResolution.x / iResolution.y, 1.);
    float t = time_f;
    vec3 a = texture(samp, tc).rgb * .56;
    float w = .56;
    for (int i = 0; i < SIZE; i++) {
        float n = float(i + 1), q = n / float(SIZE);
        vec2 z = p * vec2(1. + q * .8, 1. - q * .3);
        float g = sin(z.x * 21. + sin(z.y * 7. + t) + n) + sin(z.y * 19. - t * .7 + n);
        z += .025 * vec2(cos(g * 2.), sin(g * 1.7)) * q;
        vec3 h = texture(textures[i], mir(z / vec2(iResolution.x / iResolution.y, 1.) + .5)).rgb;
        float k = pow(.85, n);
        a += h * P(g * .04 + t * .02) * k;
        w += k;
    }
    color = vec4(clamp((a / w) / (1. + a / w), 0., 1.), 1.);
}
