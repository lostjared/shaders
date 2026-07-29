#version 330

in vec2 tc;
out vec4 color;
uniform sampler2D samp;

void main(void) {
    color = texture(samp, tc);
    vec4 color2 = texture(samp, tc / 2);
    vec4 color3 = texture(samp, tc/ 4);
    vec4 color4 = texture(samp, tc/ 8);

    color[0] = (0.4 * color[2]) + (0.4 * color2[1]) + (0.4 * color3[1]) + (0.4 * color4[0]);

    color[1] = (0.4 * color[1]) + (0.4 * color2[1]) + (0.4 * color3[2]) + (0.4 * color4[0]);

    color[2] = (0.4 * color[0]) + (0.4 * color2[2]) + (0.4 * color3[2]) + (0.4 * color4[1]);
}