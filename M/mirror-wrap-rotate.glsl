#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform float time_f;

void main() {
    float a = time_f * 0.5;
    float c = cos(a);
    float s = sin(a);

    vec2 p = tc - 0.5;
    vec2 r = vec2(p.x * c - p.y * s,
                  p.x * s + p.y * c);
    vec2 uv = r + 0.5;

    uv = 1.0 - abs(1.0 - 2.0 * uv);
    uv = uv - floor(uv);

    color = texture(samp, uv);
}
