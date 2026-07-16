#version 330 core
in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;

vec2 safeUV(vec2 p) {
    return 1.0 - abs(mod(p, 2.0) - 1.0);
}

float surface(vec2 p, float t) {
    float h = sin(dot(p, vec2(13.0, 9.0)) + t * 1.7);
    h += 0.55 * sin(dot(p, vec2(-8.0, 17.0)) - t * 1.25);
    h += 0.28 * sin(dot(p, vec2(25.0, 6.0)) + t * 2.1);
    return h;
}

void main(void) {
    float e = 0.0025;
    float h = surface(tc, time_f);
    vec2 n =
        vec2(surface(tc + vec2(e, 0.0), time_f) - h, surface(tc + vec2(0.0, e), time_f) - h) / e;
    vec2 uv = safeUV(tc + n * 0.0018);
    vec4 src = texture(samp, uv);
    float caustic = pow(max(0.0, 1.0 - length(n) * 0.055), 7.0);
    vec3 lit = src.rgb * (0.94 + 0.20 * caustic);
    lit += vec3(0.03, 0.11, 0.14) * caustic;
    color = vec4(lit, texture(samp, tc).a);
}
