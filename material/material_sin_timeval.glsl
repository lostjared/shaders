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

float random (vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}

void main(void)
{
    color = texture(samp, tc);
    vec4 mat_color = texture(mat_samp, tc);
    vec4 color2 = color * sin(tc[0] * timeval);
    vec4 color3 = mat_color * sin(tc[1] * timeval);
    vec4 color4 = ((0.5 * mat_color) + (0.5 * color)) + cos(tc[0]+tc[1] * timeval);
    color = (0.4 * color) + (0.4 * color2) + (0.4 * color3) + (0.4 * color4);
}

