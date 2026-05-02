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
uniform vec2 iResolution;

uniform float restore_black;

void main(void) {
    color = texture(samp, tc);
    vec4 back_color = color;
    float x = gl_FragCoord.x / 16;
    float y = gl_FragCoord.y / 16;
    color[0] += (color[0] * 255 / x) / 255;
    color[1] = 0;
    color[2] += (color[2] * 255 / y) / 255;

    color[0] = color[0] * 0.8;
    color[2] = color[2] * 0.8;
}
