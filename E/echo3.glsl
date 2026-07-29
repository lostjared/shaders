#version 330

in vec2 tc;
out vec4 color;
uniform sampler2D samp;

void main(void) {
    color = texture(samp, tc);
    vec4 color2 = texture(samp, tc/3);
    vec4 color3 = texture(samp, tc/5);
    vec4 color4 = texture(samp, tc/9);
    vec4 color5 = texture(samp, tc/15);
    color = (color * 0.3) + (color2 * 0.3) + (color3 * 0.3) + (color4 * 0.3) + (color5 * 0.3);
}