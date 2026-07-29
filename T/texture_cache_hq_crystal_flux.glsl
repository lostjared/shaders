#version 330 core
#ifndef SIZE
#define SIZE 8
#endif
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform sampler2DArray history;
uniform int history_head;
#ifndef SIZE
#define SIZE 8
#endif
#ifndef CACHE_HISTORY_LAYER
#define CACHE_HISTORY_LAYER(index) ((history_head + (index)) % SIZE)
#endif
uniform vec2 iResolution;
uniform float time_f;
vec2 mir(vec2 u) { return 1. - abs(mod(u, 2.) - 1.); }
vec3 P(float x) { return .5 + .5 * cos(6.28318 * (x + vec3(.05, .3, .58))); }
void main() {
    vec2 p = (tc - .5) * vec2(iResolution.x / iResolution.y, 1.);
    float t = time_f;
    vec3 a = texture(samp, tc).rgb * .58;
    float w = .58;
    for (int i = 0; i < SIZE; i++) {
        float n = float(i + 1), q = n / float(SIZE);
        vec2 z = p;
        for (int j = 0; j < 3; j++) {
            z = abs(z) / max(dot(z, z), .12) - .72;
            z += .08 * vec2(sin(t * .4 + n), cos(t * .37 - n));
        }
        z *= .35 + .8 * q;
        vec3 h = texture(history, vec3(mir(z / vec2(iResolution.x / iResolution.y, 1.) + .5), float(CACHE_HISTORY_LAYER(i)))).rgb;
        float k = pow(.8, n);
        a += h * P(q * 1.4 + t * .025) * k;
        w += k;
    }
    vec3 c = a / w;
    color = vec4(clamp(c / (1. + c), 0., 1.), 1.);
}
