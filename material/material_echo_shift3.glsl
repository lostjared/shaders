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
uniform sampler2D mat_samp;
uniform float value_alpha_r, value_alpha_g, value_alpha_b;
uniform float index_value;
uniform float time_f;

uniform float restore_black;

void main(void) {
    color = texture(samp, tc);

    float value1 = 2, value2 = 2, value3 = 3, value4 = 4;

    if (alpha_r > 0 && alpha_r < 0.3) {
        value1 = 2;
        value2 = 4;
        value3 = 6;
        value4 = 8;
    } else if (alpha_r > 0.3 && alpha_r < 0.7) {
        value1 = 3;
        value2 = 5;
        value3 = 7;
        value4 = 9;
    } else {
        value1 = 2;
        value2 = 3;
        value3 = 6;
        value4 = 9;
    }
    vec4 color2 = texture(samp, tc / value1);
    vec4 color3 = texture(mat_samp, tc / value2);
    vec4 color4 = texture(samp, tc / value3);
    vec4 color5 = texture(mat_samp, tc / value4);
    color = (color * 0.3) + (color2 * 0.3) + (color3 * 0.3) + (color4 * 0.3) + (color5 * 0.3);
}
