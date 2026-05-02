#version 330
in vec2 tc;
out vec4 color;
uniform float alpha_r;
uniform float alpha_g;
uniform float alpha_b;
uniform float alpha;
uniform vec4 optx;
uniform vec4 random_var;
uniform float alpha_value;
uniform mat4 mv_matrix;
uniform mat4 proj_matrix;
uniform sampler2D samp;
uniform float value_alpha_r, value_alpha_g, value_alpha_b;
uniform float index_value;
uniform float time_f;

uniform float restore_black;

void main(void) {
    color = texture(samp, tc);
    vec4 source = color;
    float val = cos((color[0] + color[1] + color[2]) * alpha);

    for (int q = 0; q < 3; ++q)
        color[q] = color[q] * (val * color[q] / 0.3);

    color = (0.5 * color) + (0.7 * source);
}
