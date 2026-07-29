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
vec3 P(float x) { return .5 + .5 * cos(6.28318 * (x + vec3(.1, .38, .7))); }
void main() {
    vec2 p = (tc - .5) * vec2(iResolution.x / iResolution.y, 1.);
    float t = time_f, r = max(length(p), .001), w = .48;
    vec3 a = texture(samp, tc).rgb * .48;
    for (int i = 0; i < SIZE; i++) {
        float n = float(i + 1), q = n / float(SIZE);
        float z = 1. / r + n * .12 + t * .35;
        vec2 u = p / r;
        u = vec2(u.x * cos(z * .12) - u.y * sin(z * .12), u.x * sin(z * .12) + u.y * cos(z * .12));
        u *= .22 + q * .08;
        u += .03 * sin(z * vec2(1.7, 1.3) + n);
        vec3 h = texture(history, vec3(mir(u + .5), float(CACHE_HISTORY_LAYER(i)))).rgb;
        float k = pow(.83, n);
        a += h * P(z * .03 + q) * k;
        w += k;
    }
    color = vec4(clamp((a / w) / (1. + a / w), 0., 1.), 1.);
}
