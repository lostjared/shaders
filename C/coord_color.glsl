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
uniform float value_alpha_r, value_alpha_g, value_alpha_b;
uniform float index_value;
uniform float time_f;
uniform vec2 iResolution;
in vec2 iResolution_;
uniform float restore_black;
uniform vec4 inc_valuex;

void main(void)
{
    color = texture(samp, tc);
    vec2 pos = gl_FragCoord.xy/iResolution_.xy;
    vec4 s = color * sin(inc_valuex/255 * timeval);
    color[0] += s[0] * pos[0];
    color[1] += s[1] * pos[1];
}
