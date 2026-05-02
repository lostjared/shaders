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
uniform vec2 iResolution;
uniform float restore_black;

float random(vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898, 78.233))) *
                 43758.5453123);
}

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
    vec4 color2;
    color2 = texture(mat_samp, tc);
    if (color[0] < 0.1 && color[1] < 0.1 && color[2] < 0.1) {
        color = color2;
    } else {
        ivec4 source_color = ivec4(color * 255);
        ivec4 final_color = ivec4(color2 * 255);
        color = xor_RGB(final_color, source_color);
    }
}
