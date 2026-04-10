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
uniform vec2 iResolution;
uniform float restore_black;
uniform vec4 inc_value;

float random (vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}

void main(void)
{
    color = texture(samp, tc);
    vec4 color2,color3,color4;
    color2 = texture(mat_samp, tc);
    vec2 pos1 = tc;
    vec2 pos2 = tc;
    
    pos1[0] -= 0.01;
    pos2[0] += 0.01;
    
    color3 = texture(samp, pos1);
    color4 = texture(mat_samp, pos2);
    
    color = (0.3 * color) + (0.3 * color2) + (0.3 * color3) + (0.3 * color4);
    
}
