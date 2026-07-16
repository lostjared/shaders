#version 330 core

in vec2 tc;
out vec4 color;

uniform sampler2D samp;

void main() {
    vec2 p = abs(tc - 0.5);
    if (p.y > p.x) {
        p = p.yx;
    }
    vec2 uv = p + 0.5;
    color = texture(samp, uv);
}
