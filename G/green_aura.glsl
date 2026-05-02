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
    ivec3 source;
    for (int i = 0; i < 3; ++i) {
        source[i] = int(255 * color[i]);
    }
    float x = gl_FragCoord.x / iResolution_.x / 3;
    float y = gl_FragCoord.y / iResolution_.y / 3;
    color[0] = color[0] * asin(fract(x / 3) * 0.3421);
    color[1] = color[1] * acos(fract(y / 3) * 0.1249);
    color[2] = color[2] * atan(fract(x + y / 3) * 0.2912);

    ivec3 int_color;
    for (int i = 0; i < 3; ++i) {
        int_color[i] = int(255 * color[i]);
        int_color[i] = int_color[i] ^ source[i];
        if (int_color[i] > 255)
            int_color[i] = int_color[i] % 255;
        color[i] = float(int_color[i]) / 255;
    }
}
