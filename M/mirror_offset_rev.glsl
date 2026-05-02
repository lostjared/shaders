#version 330
in vec2 tc;
out vec4 color;
uniform float alpha_r;
uniform float alpha_g;
uniform float alpha_b;
uniform float alpha;
in vec3 vpos;
uniform vec4 optx;
uniform vec4 random_var;
uniform float alpha_value;
uniform mat4 mv_matrix;
uniform mat4 proj_matrix;
uniform sampler2D samp;
uniform float value_alpha_r, value_alpha_g, value_alpha_b;
uniform float index_value;
uniform float time_f;

uniform float restore_black;
in vec2 iResolution_;

void main(void) {
    color = texture(samp, tc);
    vec2 pos = gl_FragCoord.xy / iResolution_.xy;
    vec2 vpos = tc;

    vpos[0] = vpos[0] + alpha_r;
    vpos[1] = alpha_g - vpos[1];
    vec4 color2 = texture(samp, vpos);
    color = (0.5 * color) + (0.5 * color2);
}
