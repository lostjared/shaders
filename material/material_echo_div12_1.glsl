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
    color = (0.5 * texture(samp, tc)) + (0.5 * texture(mat_samp, tc));

    vec2 tc1 = tc;
    vec2 tc2 = tc;

    tc1[0] = 1.0 - tc1[0];
    tc1[1] = tc1[1] / 2;
    tc2[1] = 1.0 - tc2[1];
    tc2[0] = tc2[0] / 2;

    vec4 color2 = texture(samp, tc);
    vec4 color3 = texture(mat_samp, tc1);
    vec4 color4 = texture(samp, tc2);
    color = (color * 0.3) + (color2 * 0.3) + (color3 * 0.3) + (color4 * 0.3);
}
