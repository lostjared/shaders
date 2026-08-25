#version 450

layout(set = 0, binding = 1, std140) uniform SpriteExtended {
    vec4 mouse;
    vec4 u0;
    vec4 u1;
    vec4 u2;
    vec4 u3;
    vec4 custom_uniforms[16];
    vec4 audio_bands;
    vec4 audio_history;
} ext;
#define history_head int(ext.u3.x)
#define iResolution ext.u0.zw
#define time_f ext.u2.y

#ifndef SIZE
#define SIZE 8
#endif
layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;
layout(set = 0, binding = 2) uniform sampler2DArray history;

#ifndef SIZE
#define SIZE 8
#endif
#ifndef CACHE_HISTORY_LAYER
#define CACHE_HISTORY_LAYER(index) ((history_head + (index)) % SIZE)
#endif


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
