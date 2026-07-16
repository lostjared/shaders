#version 330 core

in vec2 tc;
out vec4 color;

uniform sampler2D samp;

void main() {
    vec2 uv = 0.5 + abs(tc - 0.5);
    color = texture(samp, uv);
}
