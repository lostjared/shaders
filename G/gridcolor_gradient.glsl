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

uniform float restore_black;
in vec2 iResolution_;

vec4 xor_RGB(vec4 icolor, ivec4 isource) {
    ivec3 int_color;
    for (int i = 0; i < 3; ++i) {
        int_color[i] = int(255 * icolor[i]);
        int_color[i] = int_color[i] ^ isource[i];
        if (int_color[i] > 255)
            int_color[i] = int_color[i] % 255;
        icolor[i] = float(int_color[i]) / 255;
    }
    icolor.a = 1.0;
    return icolor;
}

void main(void) {
    color = texture(samp, tc);
    ivec4 source = ivec4(255 * color);
    vec2 pos = gl_FragCoord.xy / iResolution_.xy;

    pos[0] += 0.01;
    pos[1] += 0.01;
    vec4 color2 = texture(samp, pos);
    color *= vec4(tc, tc[0] + tc[1], 1);
    color = (color * 0.5) + (0.5 * color2);
    color = xor_RGB(color, source);
}
