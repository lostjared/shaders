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

vec4 shift_vec(vec4 inputv, int dir) {
    vec4 rev;
    if(dir == 1) {
        rev[0] = inputv[2];
        rev[1] = inputv[0];
        rev[2] = inputv[1];
    } else {
        rev[0] = inputv[1];
        rev[1] = inputv[2];
        rev[2] = inputv[0];
    }
    return rev;
}

void main(void)
{
    color = texture(samp, tc);
    vec4 color2 = texture(samp, tc/4);
    vec4 color3 = texture(samp, tc/7);
    vec4 color4 = texture(samp, tc/11);
    vec4 color5 = texture(samp, tc/18);
    color = (color * 0.3) + (shift_vec(color2, 1) * 0.3) + (color3 * 0.3) + (shift_vec(color4, 0) * 0.3) + (color5 * 0.3);
}

