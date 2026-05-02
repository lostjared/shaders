#version 330
in vec2 tc;
out vec4 color;
uniform float alpha_r;
uniform float alpha_g;
uniform float alpha_b;
in float timeval;
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
uniform vec2 iResolution;

uniform float restore_black;
uniform vec4 inc_valuex;
uniform vec4 inc_value;

void main(void) {
    color = texture(samp, tc);
    vec2 pos1 = tc;
    vec2 pos2 = tc;
    pos1 += (fract(timeval) + 0.01) * 0.02;
    pos2 += (fract(timeval) + 0.02) * 0.03;
    vec4 color2 = texture(samp, pos1);
    vec4 color3 = texture(samp, pos2);
    color[1] = color2[1];
    color[2] = color3[2];
}
