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
vec3 P(float x) { return .5 + .5 * cos(6.28318 * (x + vec3(.0, .25, .55))); }
void main() {
    vec2 p = (tc - .5) * vec2(iResolution.x / iResolution.y, 1.);
    float t = time_f, r = length(p), a0 = atan(p.y, p.x);
    vec3 a = texture(samp, tc).rgb * .6;
    float w = .6;
    for (int i = 0; i < SIZE; i++) {
        float n = float(i + 1), q = n / float(SIZE),
              aa = abs(mod(a0 + t * .12 + n * .17, 6.28318 / 12.) - 3.14159 / 12.);
        vec2 z = vec2(cos(aa), sin(aa)) * r;
        z += .04 * sin(z.yx * vec2(17., 23.) + t + n) * q;
        vec3 h = texture(history, vec3(mir(z / vec2(iResolution.x / iResolution.y, 1.) + .5), float(CACHE_HISTORY_LAYER(i)))).rgb;
        float k = pow(.87, n);
        a += h * P(q + r + t * .03) * k;
        w += k;
    }
    color = vec4(clamp((a / w) / (1. + a / w), 0., 1.), 1.);
}
