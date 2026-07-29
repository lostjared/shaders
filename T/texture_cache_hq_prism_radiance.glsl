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
vec3 P(float x) { return .5 + .5 * cos(6.28318 * (x + vec3(.0, .27, .61))); }
void main() {
    vec2 p = (tc - .5) * vec2(iResolution.x / iResolution.y, 1.);
    float t = time_f;
    vec3 a = texture(samp, tc).rgb * .64;
    float w = .64;
    for (int i = 0; i < SIZE; i++) {
        float n = float(i + 1), q = n / float(SIZE);
        vec2 z = p;
        z.x = abs(z.x) - .16 * sin(t * .3 + n);
        z = abs(z);
        z *= 1.2 + q;
        z.y += .06 * sin(z.x * 25. - t + n);
        vec3 h = texture(history, vec3(mir(z / vec2(iResolution.x / iResolution.y, 1.) + .5), float(CACHE_HISTORY_LAYER(i)))).rgb;
        float k = pow(.88, n);
        a += h * P(q + z.x * 1.2 + t * .04) * k;
        w += k;
    }
    color = vec4(clamp((a / w) / (1. + a / w), 0., 1.), 1.);
}
