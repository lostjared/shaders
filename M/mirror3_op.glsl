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

vec4 opposite(vec4 inputx) {
    ivec4 col = ivec4(inputx * 255);
    col[0] = 255 - col[0];
    col[1] = 255 - col[1];
    col[2] = 255 - col[2];
    vec4 val;
    for (int i = 0; i < 4; ++i) {
        val[i] = float(col[i]) / 255;
    }
    return val;
}

void main(void) {
    color = texture(samp, tc);
    ivec4 source = ivec4(255 * color);
    vec2 pos = gl_FragCoord.xy / iResolution_.xy;
    vec2 vpos;
    vpos[1] = 1.0 - tc[1];
    vpos[0] = tc[0];
    vec4 color2 = opposite(texture(samp, vpos));
    color = (0.5 * color) + (0.5 * color2);
}
