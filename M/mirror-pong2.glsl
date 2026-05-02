#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

float pingPong(float x, float length) {
    float m = mod(x, length * 2.0);
    return m <= length ? m : length * 2.0 - m;
}

float h1(float n) { return fract(sin(n) * 43758.5453123); }
vec2 h2(float n) { return fract(sin(vec2(n, n + 1.0)) * vec2(43758.5453, 22578.1459)); }

void main(void) {
    float rate = 0.35;
    float t = time_f * rate;
    float k = floor(t);
    float a = fract(t);
    a = a * a * (3.0 - 2.0 * a);

    vec2 p0 = h2(k) * 2.0 - 1.0;
    vec2 p1 = h2(k + 1.0) * 2.0 - 1.0;
    vec2 shift = mix(p0, p1, a) * 0.12;

    float s0 = 0.9 + 0.2 * h1(k + 10.0);
    float s1 = 0.9 + 0.2 * h1(k + 11.0);
    float scale = mix(s0, s1, a);

    float dir = sign(h1(k + 20.0) - 0.5);
    float modulatedTime = pingPong(time_f + h1(k + 30.0) * 2.0, 5.0);
    float rot = dir * modulatedTime;

    vec2 center = vec2(0.5) + shift;
    vec2 uv = 1.0 - abs(1.0 - 2.0 * tc);
    uv = uv - floor(uv);
    vec2 d = uv - center;
    float ang = atan(d.y, d.x) + rot;
    float r = length(d) / scale;
    vec2 rotatedTC = center + r * vec2(cos(ang), sin(ang));
    rotatedTC = fract(rotatedTC);

    color = texture(samp, rotatedTC);
}
