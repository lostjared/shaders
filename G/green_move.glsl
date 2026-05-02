
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
in vec2 iResolution_;

void main(void) {
    color = texture(samp, tc);
    vec2 pos = gl_FragCoord.xy / iResolution_.xy;
    vec4 l = vec4(0.2, 0.8, 0.2, 1.0);
    color = vec4(pos, 1, 1) * l * color * alpha;
}
