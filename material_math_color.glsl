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
uniform sampler2D mat_samp;

uniform float value_alpha_r, value_alpha_g, value_alpha_b;
uniform float index_value;
uniform float time_f;
uniform vec2 iResolution;
uniform float restore_black;
uniform vec2 mat_size;
uniform vec4 inc_valuex;

float random (vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}

void main(void)
{
    color = texture(samp, tc);
    vec4 mat_color = texture(mat_samp, tc);
    vec4 col1 = mat_color * sin((inc_valuex/255) * timeval);
    
    vec4 col2 = mat_color * cos((inc_valuex/255) * timeval);
        
    color = (0.4 * color) + (0.4 * col1) + (0.4 * col2);
}
