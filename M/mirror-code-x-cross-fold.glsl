#version 330 core

in vec2 tc;
out vec4 color;

uniform sampler2D samp;

void main() {
    vec2 p = tc - 0.5;
    if (abs(p.y) > abs(p.x)) {
        p = p.yx;
    }
    p.y = abs(p.y);
    vec2 uv = p + 0.5;
    color = texture(samp, uv);
}
