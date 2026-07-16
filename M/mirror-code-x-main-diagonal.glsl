#version 330 core

in vec2 tc;
out vec4 color;

uniform sampler2D samp;

void main() {
    vec2 uv = tc;
    if (uv.y < uv.x) {
        uv = uv.yx;
    }
    color = texture(samp, uv);
}
