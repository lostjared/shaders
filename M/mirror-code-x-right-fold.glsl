#version 330 core

in vec2 tc;
out vec4 color;

uniform sampler2D samp;

void main() {
    vec2 uv = vec2(0.5 + abs(tc.x - 0.5), tc.y);
    color = texture(samp, uv);
}
