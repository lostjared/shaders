#version 330 core
in vec2 tc;
out vec4 color;
uniform float time_f;
uniform sampler2D samp;
uniform vec2 iResolution;

void main() {
    float t = time_f;
    vec2 uv = tc;

    vec2 p = uv * 2.0 - 1.0;
    float r2 = dot(p, p);
    p += p * r2 * 0.035 * sin(t * 0.4);
    uv = p * 0.5 + 0.5;

    vec2 d1 = vec2(sin(uv.y * 12.0 - t * 2.0), cos(uv.x * 12.0 + t * 1.6)) * 0.015;
    vec2 d2 = vec2(sin((uv.x + uv.y) * 24.0 + t * 1.2), -cos((uv.x - uv.y) * 24.0 - t * 1.8)) * 0.009;
    vec2 d3 = vec2(cos(uv.y * 40.0 + t * 3.5), sin(uv.x * 40.0 - t * 3.0)) * 0.003;

    uv += d1 + d2 + d3;
    uv = clamp(uv, 0.0, 1.0);

    color = texture(samp, uv);
}
