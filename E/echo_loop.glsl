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

vec4 echo_loop(vec4 color, int count) {
    vec4 col = color;
    for(int i = 2; i < count; i += 2) {
        vec4 pos = texture(samp, tc/ (i * fract(time_f)));
        col = (0.6 * col) + (0.3 * pos);
    }
    return col;
}

void main(void)
{
    color = texture(samp, tc);
    color = echo_loop(color, 14);
}

