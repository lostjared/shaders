#version 330 core

in vec2 tc;
out vec4 color;
uniform sampler2D samp;

void main(void) {
    color = texture(samp, tc);
}

