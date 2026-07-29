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

vec4 reverse_vec(vec4 inputv) {
    vec4 rev;
    rev[0] = inputv[2];
    rev[1] = inputv[1];
    rev[2] = inputv[0];
    return rev;
}

void main(void)
{
    color = texture(samp, tc);
    vec4 color2 = texture(samp, tc);
    vec4 color3 = texture(mat_samp, tc/3);
    vec4 color4 = texture(samp, tc/6);
    vec4 color5 = texture(mat_samp, tc/6);
    color = (color * 0.3) + (reverse_vec(color2) * 0.3) + (color3 * 0.3) + (reverse_vec(color4) * 0.3) + (color5 * 0.3);
}

