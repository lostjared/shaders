#version 330 core
out vec4 color;
in vec2 tc;
uniform float time_f;
uniform sampler2D samp;

float PI = 3.1415926535897932384626433832795;

float pingPong(float x, float length) {
    float m = mod(x, length * 2.0);
    return m <= length ? m : length * 2.0 - m;
}

void main() {
    vec2 uv = 1.0 - abs(1.0 - 2.0 * tc);
    color = texture(samp, sin(uv * pingPong(time_f * PI, 3.0)));
}
