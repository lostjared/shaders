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

uniform float restore_black;

void main(void) {
    color = texture(samp, tc);
    vec4 color2, color3, color4, color5;
    vec2 st = gl_FragCoord.xy;
    color2 = texture(samp, tc / 2);
    color3 = texture(mat_samp, tc / 2);
    color4 = texture(samp, tc / 3);
    color5 = texture(mat_samp, tc / 3);

    if (int(st[0]) % 2 == 0 && int(st[1]) % 2 == 0) {
        color = (color * 0.3) + (color2 * 0.3) + (color3 * 0.3) + (color4 * 0.3) + (color5 * 0.3);

    } else {
        color = (color * 0.5) + (color2 * 0.2) + (color3 * 0.2) + (color4 * 0.2) + (color5 * 0.2);
    }
}
