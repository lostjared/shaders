#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform float time_f;

void main() {
    vec2 p = tc - 0.5;

    float r = max(abs(p.x), abs(p.y)) * 2.0;
    float w = 1.0 - smoothstep(0.7, 1.0, r);
    w *= w;

    float a = time_f * 0.8 * w;
    float c = cos(a);
    float s = sin(a);

    vec2 q = vec2(p.x * c - p.y * s,
                  p.x * s + p.y * c) + 0.5;

    vec2 uv = 1.0 - abs(1.0 - 2.0 * q);
    uv = fract(uv);

    color = texture(samp, uv);
}
