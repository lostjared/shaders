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

float random(vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898, 78.233))) *
                 43758.5453123);
}

void main(void) {
    color = texture(samp, tc);
    vec4 color2;
    color2 = texture(mat_samp, tc);
    color[0] = 1.5 * (color[0] * fract(alpha_r * timeval));
    color[1] = 1.5 * (color[1] * fract(alpha_g * timeval));
    color[2] = 1.5 * (color[2] * fract(alpha_b * timeval));

    color = color + color2;
}
