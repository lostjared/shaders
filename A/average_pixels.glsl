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

void main(void)
{
    color = texture(samp, tc);
    vec4 color2 = texture(samp, tc+0.01);
    vec4 color3 = texture(samp, tc-0.01);
    vec2 pos = tc;
    pos[0] -= 0.01;
    vec2 pos2 = tc;
    pos2[1] += 0.01;
    vec4 color4 = texture(samp, pos);
    vec4 color5 = texture(samp, pos2);
    
    color = (color + color2 + color3 + color4 + color5) / 5;
}

