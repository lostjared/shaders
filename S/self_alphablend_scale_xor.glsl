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

void main(void) {

    color = texture(samp, tc);
    vec4 color2 = color;
    ivec4 color_source = ivec4(color * 255);
    color = color * alpha;
    ivec4 colori = ivec4(color * 255);
    for (int i = 0; i < 3; ++i) {
        if (colori[i] >= 255)
            colori[i] = colori[i] % 255;

        if (color_source[i] >= 255)
            color_source[i] = color_source[i] % 255;

        colori[i] = colori[i] ^ color_source[i];
        color[i] = float(colori[i]) / 255;
    }

    for (int i = 0; i < 3; ++i)
        if (color[i] < 0.2)
            color[i] = color2[i];
}
