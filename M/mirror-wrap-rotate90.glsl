#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform float time_f;

void main() {
    float a = time_f * 0.5;
    float c = cos(a);
    float s = sin(a);

    vec2 p = tc - 0.5;
    vec2 uv = vec2(p.x * c - p.y * s,
                   p.x * s + p.y * c) + 0.5;

    uv = abs(fract(uv) * 2.0 - 1.0);

    color = texture(samp, uv);
}
