
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
    vec4 cstart = color;
    vec4 colors[4];
    colors[0] = texture(mat_samp, tc);
    colors[1] = texture(mat_samp, tc / 2);
    colors[2] = texture(mat_samp, tc / 8);
    colors[3] = texture(samp, tc / 2);

    for (int i = 0; i < 4; ++i) {
        color *= colors[i];
    }
    color = color * cstart * 30.0;
}
