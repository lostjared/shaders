#version 330 core

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float time_f;

mat2 rotate2D(float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return mat2(c, -s, s, c);
}

void main() {
    float angle = time_f * 0.35;
    vec2 p = rotate2D(-angle) * (tc - 0.5);
    p.x = abs(p.x);
    vec2 uv = rotate2D(angle) * p + 0.5;
    color = texture(samp, clamp(uv, 0.0, 1.0));
}
