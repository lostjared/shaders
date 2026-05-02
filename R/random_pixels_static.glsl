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
uniform vec4 inc_valuex;
uniform vec4 inc_value;

uniform float restore_black;

float random(vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898, 78.233))) *
                 43758.5453123);
}

void main(void) {
    color = texture(samp, tc);
    vec4 color2 = texture(samp, tc / 2);
    vec2 pos1 = tc;
    vec2 pos2 = tc;
    vec4 iv1 = inc_valuex / 255;
    vec4 iv2 = inc_value / 255;
    pos1[0] - tc[0] - iv1[0];
    pos1[1] = tc[1] - iv1[1];
    pos2[0] = tc[0] - iv2[0];
    pos2[1] = tc[1] - iv2[1];
    vec2 pos3 = tc;
    pos3[0] = tc[0] - iv1[2];
    pos3[1] = tc[1] - iv2[2];
    float rand_x = random(pos1);
    float rand_y = random(pos2);
    float rand_z = random(pos3);
    color = (0.5 * color) + (0.5 * vec4(rand_x, rand_y, rand_z, 1));
}
