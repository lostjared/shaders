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

void main(void) {
    color = texture(samp, tc);
    ivec4 source = ivec4(color * 255);
    ivec4 inc = ivec4(inc_valuex);
    ivec4 inc_v = ivec4(inc_value);

    source += inc + inc_v;

    for (int i = 0; i < 3; ++i) {
        source[i] = source[i] % 255;
        color[i] = float(source[i]) / 255;
    }
}
