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

void main(void) {
    float t = time_f;
    vec2 p = tc * 2.0 - 1.0;
    float k = 10.0;
    float a = 0.35 + 0.25 * sin(t * 1.7);
    p += a * vec2(sin((p.y + t) * k), cos((p.x - t) * k));
    float r = length(p);
    float ang = atan(p.y, p.x) + a * 4.0 * r * r + t * 1.2;
    vec2 s = vec2(cos(ang), sin(ang)) * r;
    vec2 uv = s * 0.5 + 0.5;
    uv.x = pingPong(uv.x + t * 1.8, 1.0);
    uv.y = pingPong(uv.y + t * 1.8, 1.0);
    color = texture(samp, uv);
}
