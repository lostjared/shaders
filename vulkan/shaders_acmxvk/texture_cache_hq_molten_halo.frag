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
vec3 P(float x) { return .5 + .5 * cos(6.28318 * (x + vec3(.02, .22, .56))); }
void main() {
    vec2 p = (tc - .5) * vec2(iResolution.x / iResolution.y, 1.);
    float t = time_f, r = length(p);
    vec3 a = texture(samp, tc).rgb * .61;
    float w = .61;
    for (int i = 0; i < SIZE; i++) {
        float n = float(i + 1), q = n / float(SIZE);
        vec2 z = p * (1. + q * .4);
        float wave = sin(r * 16. - t * 1.3 + n) + .5 * sin(r * 31. + t * .8 - n);
        z += normalize(p + vec2(.001)) * wave * .018 * q;
        vec3 h = texture(history, vec3(mir(z / vec2(iResolution.x / iResolution.y, 1.) + .5), float(CACHE_HISTORY_LAYER(i)))).rgb;
        float k = pow(.84, n);
        a += h * P(wave * .08 + q + t * .02) * k;
        w += k;
    }
    float halo = smoothstep(.7, .05, r);
    color = vec4(clamp((a / w) / (1. + a / w) + halo * .1 * P(t * .03), 0., 1.), 1.);
}
