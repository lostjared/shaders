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

vec4 xor_RGB(vec4 icolor, ivec4 isource) {
    ivec3 int_color;
    for(int i = 0; i < 3; ++i) {
        int_color[i] = int(255 * icolor[i]);
        int_color[i] = int_color[i]^isource[i];
        if(int_color[i] > 255)
            int_color[i] = int_color[i]%255;
        icolor[i] = float(int_color[i])/255;
    }
    icolor.a = 1.0;
return icolor;
}

void main(void)
{
    color = texture(samp, tc);
    vec4 tcolor = color;
    ivec4 source = ivec4(color * 255) / 2;
    mat4 matrix = mat4(
                 tc[0], tc[1], tc[1], tc[0],
                 tc[1], tc[0], tc[0], tc[1],
                 tc[0], tc[0], tc[1], tc[0],
                1,1,1,1);
    
    color = color * matrix;
    color = xor_RGB(color, source);
    color = (0.5 * tcolor) + (0.5 * color);
}

