#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;

void main() {
    vec2 uv = 1.0 - abs(1.0 - 2.0 * tc);
    uv = uv - floor(uv);     
    color = texture(samp, uv);
}
