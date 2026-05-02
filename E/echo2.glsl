#version 330

in vec2 tc;
out vec4 color;
uniform sampler2D samp;

void main(void) {
    color = texture(samp, tc);
    vec4 color2 = texture(samp, tc / 4);
    vec4 color3 = texture(samp, tc / 8);
    vec4 color4 = texture(samp, tc / 12);
    color = (color * 0.4) + (color2 * 0.4) + (color3 * 0.4) + (color4 * 0.4);
}