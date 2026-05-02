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
    vec4 color2 = texture(mat_samp, tc);

    ivec3 source;
    for (int i = 0; i < 3; ++i) {
        source[i] = int(255 * color[i]);
    }

    color = ((color * 0.5) * (alpha / 4)) + ((color2 * 0.5) * (alpha / 4));

    color *= 2;

    ivec3 int_color;
    for (int i = 0; i < 3; ++i) {
        int_color[i] = int(255 * color[i]);
        int_color[i] = int_color[i] ^ source[i];
        if (int_color[i] > 255)
            int_color[i] = int_color[i] % 255;
        color[i] = float(int_color[i]) / 255;
    }
}
