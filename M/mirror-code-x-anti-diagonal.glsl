#version 330 core

in vec2 tc;
out vec4 color;

uniform sampler2D samp;

void main() {
    vec2 uv = tc;
    if (uv.x + uv.y > 1.0) {
        uv = 1.0 - uv.yx;
    }
    color = texture(samp, uv);
}
