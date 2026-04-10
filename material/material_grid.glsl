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

void main(void)
{
    color = texture(samp, tc);
    vec4 color2 = texture(mat_samp, tc);
    //vec4 value = vec4(0.2, 0.1, 0.8, 1.0);
    vec2 color_value = gl_FragCoord.xy / 16;
    float value1 = sin(color_value.x);
    float value2 = cos(color_value.y);
    
    color = color * color2 * value1 * value2;
}

