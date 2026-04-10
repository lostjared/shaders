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

float random (vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}

vec4 clipColor(vec4 colorx) {
    ivec4 rgb;
    for(int i = 0; i < 3; ++i) {
        rgb[i] = int(colorx[i] * 255);
        if(rgb[i] > 255)
            rgb[i] = rgb[i]%255;
    }
    vec4 col;
    for(int i = 0; i < 3; ++i)
        col[i] = float(rgb[i])/255;
    return col;
}

void main(void)
{
    color = texture(samp, tc);
    vec4 color2;
    color2 = texture(mat_samp, tc);

    color = (alpha*color) + (1-alpha * color2);
}

