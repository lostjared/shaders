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
        vec3 h = texture(textures[i], mir(z / vec2(iResolution.x / iResolution.y, 1.) + .5)).rgb;
        float k = pow(.84, n);
        a += h * P(wave * .08 + q + t * .02) * k;
        w += k;
    }
    float halo = smoothstep(.7, .05, r);
    color = vec4(clamp((a / w) / (1. + a / w) + halo * .1 * P(t * .03), 0., 1.), 1.);
}
