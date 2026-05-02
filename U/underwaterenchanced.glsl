#version 330 core
in vec2 tc;
out vec4 color;
uniform float time_f;
uniform sampler2D samp;
uniform vec2 iResolution;

float h1(float n) { return fract(sin(n) * 43758.5453123); }
vec2 h2(float n) { return fract(sin(vec2(n, n + 1.0)) * vec2(43758.5453, 22578.1459)); }

void main() {
    float t = time_f;
    vec2 uv = tc;

    float rate = 0.35;
    float k = floor(t * rate);
    float a = fract(t * rate);
    a = a * a * (3.0 - 2.0 * a);
    vec2 p0 = h2(k);
    vec2 p1 = h2(k + 1.0);
    vec2 shift = (mix(p0, p1, a) - 0.5) * 0.08;

    vec2 c = vec2(0.5) + shift;
    vec2 p = uv - c;
    float r2 = dot(p, p);
    p += p * r2 * (0.035 + 0.01 * h1(k + 7.0)) * sin(t * (0.4 + 0.05 * h1(k + 13.0)));
    uv = p + c;

    vec2 d1 = vec2(sin(uv.y * 12.0 - t * 2.0), cos(uv.x * 12.0 + t * 1.6)) * 0.015;
    vec2 d2 = vec2(sin((uv.x + uv.y) * 24.0 + t * 1.2), -cos((uv.x - uv.y) * 24.0 - t * 1.8)) * 0.009;
    vec2 d3 = vec2(cos(uv.y * 40.0 + t * 3.5), sin(uv.x * 40.0 - t * 3.0)) * 0.003;

    uv += d1 + d2 + d3;
    uv = clamp(uv, 0.0, 1.0);

    color = texture(samp, uv);
}
