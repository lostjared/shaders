#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;

void main() {
    vec2 uv = fract(tc);
    uv = min(uv, 1.0 - uv) * 2.0; 
    uv = vec2(min(uv.x, uv.y), max(uv.x, uv.y));
    color = texture(samp, uv);
}