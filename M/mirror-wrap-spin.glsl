#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform float time_f; // or a separate angle uniform if you prefer

void main() {
    float a = time_f * 0.5; // rotation speed
    float c = cos(a);
    float s = sin(a);

    // rotate in UV space around the center of the texture
    vec2 p = tc - 0.5;
    vec2 tc_rot = vec2(
                      p.x * c - p.y * s,
                      p.x * s + p.y * c) +
                  0.5;

    // mirror tiling so edges match when used as a texture
    vec2 uv = 1.0 - abs(1.0 - 2.0 * tc_rot);
    uv = fract(uv);

    color = texture(samp, uv);
}
