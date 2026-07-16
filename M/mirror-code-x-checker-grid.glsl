#version 330 core

in vec2 tc;
out vec4 color;

uniform sampler2D samp;

vec2 mirrorRepeat(vec2 value) {
    return 1.0 - abs(mod(value, 2.0) - 1.0);
}

void main() {
    vec2 uv = mirrorRepeat(tc * vec2(6.0, 4.0));
    color = texture(samp, uv);
}
