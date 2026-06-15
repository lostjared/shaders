#version 330 core

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

const float TAU = 6.28318530718;

vec3 color_palette(float t) {
    vec3 a = vec3(0.5, 0.45, 0.5);
    vec3 b = vec3(0.6, 0.72, 0.95);
    vec3 c = vec3(0.85, 0.2, 0.25);
    vec3 d = vec3(0.3, 0.15, 0.2);
    return a + b * cos(TAU * (c * t + d)) - vec3(0.08) * sin(time_f * 0.3) +
           (t > 0.8 ? vec3(0.1) : vec3(0));
}

void main(void) {
    vec4 col = texture(samp, tc);
    color = vec4(col.rgb * color_palette(time_f), col.a);
}