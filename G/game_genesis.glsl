#version 330 core
// 16-bit Sega Genesis style palette compression.
out vec4 color;
in vec2 tc;
uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    c = floor(c * 8.0) / 7.0;
    c = clamp(c, 0.0, 1.0);
    c *= vec3(1.05, 0.98, 1.05);
    color = vec4(c, 1.0);
}
