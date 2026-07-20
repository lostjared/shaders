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
vec3 pal(float x) { return .5 + .5 * cos(6.28318 * (x + vec3(.02, .3, .63))); }
void main() {
    vec2 p = (tc - .5) * vec2(iResolution.x / iResolution.y, 1.);
    float t = time_f;
    vec3 a = texture(samp, tc).rgb * .62;
    float wt = .62;
    for (int i = 0; i < SIZE; i++) {
        float n = float(i + 1), q = n / float(SIZE);
        vec2 z = p;
        z.x += .10 * sin(z.y * 8. - t * .8 + n * .7) * q;
        z.y += .045 * sin(z.x * 13. + t * .6 - n) * q;
        z *= 1. - .12 * q;
        vec3 h = texture(textures[i], mir(z / vec2(iResolution.x / iResolution.y, 1.) + .5)).rgb;
        float k = pow(.86, n);
        a += h * mix(vec3(1), pal(q + t * .03), .7) * k;
        wt += k;
    }
    vec3 c = a / wt;
    float glow = exp(-abs(p.y + .18 * sin(p.x * 5. - t * .4)) * .22);
    color = vec4(clamp(c / (1. + c) + glow * .12 * pal(t * .05 + p.x), 0., 1.), 1.);
}
