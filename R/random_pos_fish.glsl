#version 330 core

in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;

float pingPong(float x, float length) {
    float m = mod(x, length * 2.0);
    return m <= length ? m : (length * 2.0 - m);
}

float h1(float n) { return fract(sin(n) * 43758.5453123); }
vec2 h2(float n) { return fract(sin(vec2(n, n + 1.0)) * vec2(43758.5453, 22578.1459)); }

void main(void) {
    float time_t = pingPong(time_f, 10.0) + 2.0;

    float rate = 0.8;
    float t = time_f * rate;
    float t0 = floor(t);
    float a = fract(t);
    float w = a * a * (3.0 - 2.0 * a);
    vec2 p0 = vec2(0.15) + h2(t0) * 0.7;
    vec2 p1 = vec2(0.15) + h2(t0 + 1.0) * 0.7;
    vec2 center = mix(p0, p1, w);

    vec2 uv = tc - center;
    float lenv = length(uv);
    float factor = sqrt(lenv) * 0.5;
    float s = 1.0 + sin(factor * time_t);
    uv *= s;

    color = texture(samp, uv + center);
}
