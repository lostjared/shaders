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

float random(vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898, 78.233))) *
                 43758.5453123);
}

void main(void) {
    color = texture(samp, tc);
    vec4 color21;
    color21 = texture(mat_samp, tc);
    if (color21[0] < 0.7 && color21[1] < 0.7 && color21[2] < 0.7) {

    } else {
        vec4 color2 = texture(samp, tc / 0.9);
        vec4 color3 = texture(samp, tc / 1.5);
        vec4 color4 = texture(samp, tc / 2.0);
        color = (color * 0.4) + (color2 * 0.4) + (color3 * 0.4) + (color4 * 0.4);
    }
}
