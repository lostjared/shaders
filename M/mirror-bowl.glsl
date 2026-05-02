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
    vec2 uv = 1.0 - abs(1.0 - 2.0 * tc);
    uv = uv - floor(uv);
    float rate = 0.6;
    float t = time_f * rate;
    float t0 = floor(t);
    float a = fract(t);
    float w = a * a * (3.0 - 2.0 * a);
    vec2 p0 = vec2(0.15) + h2(t0) * 0.7;
    vec2 p1 = vec2(0.15) + h2(t0 + 1.0) * 0.7;
    vec2 center = mix(p0, p1, w);

    vec2 p = uv - center;
    float r = length(p);
    float ang = atan(p.y, p.x);

    float swirl = 2.2 + 0.8 * sin(time_f * 0.35);
    float spin = 0.6 * sin(time_f * 0.2);
    ang += swirl * r + spin;

    float bend = 0.35;
    float rp = r + bend * r * r;

    vec2 uvx = center + vec2(cos(ang), sin(ang)) * rp;

    uvx += 0.02 * vec2(sin((tc.y + time_f) * 4.0), cos((tc.x - time_f) * 3.5));

    uv = vec2(pingPong(uv.x, 1.0), pingPong(uv.y, 1.0));

    color = texture(samp, uvx);
}
