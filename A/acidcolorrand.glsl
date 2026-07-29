#version 330
in vec2 tc;
out vec4 color;
uniform float alpha_r;
uniform float alpha_g;
uniform float alpha_b;
uniform float alpha;
uniform vec4 optx;
in vec4 random_value;
uniform vec4 random_var;
uniform float alpha_value;
uniform mat4 mv_matrix;
uniform mat4 proj_matrix;
uniform sampler2D samp;
uniform float value_alpha_r, value_alpha_g, value_alpha_b;
uniform float index_value;
uniform float time_f;

uniform float restore_black;

int tosmall(float f) {
    if(f >= 0 && f <= 75)
        return 0;
    if(f >= 76 && f <= 140)
        return 1;
    if(f >= 141 && f <= 255)
        return 2;
}

void main(void)
{
    color = texture(samp, tc);
    vec2 cord1 = vec2(tc[0]/2, tc[1]/2);
    vec2 cord2 = vec2(tc[0]/4, tc[1]/4);
    vec2 cord3 = vec2(tc[0]/8, tc[1]/8);
    vec4 col1 = texture(samp, cord1);
    vec4 col2 = texture(samp, cord2);
    vec4 col3 = texture(samp, cord3);
    color[0] = color[0]+col1[tosmall(random_value[0])];
    color[1] = color[1]+col2[tosmall(random_value[1])];
    color[2] = color[2]+col3[tosmall(random_value[2])];
}

