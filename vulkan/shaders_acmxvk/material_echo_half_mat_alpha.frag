#version 450

layout(set = 0, binding = 1, std140) uniform SpriteExtended {
    vec4 mouse;
    vec4 u0;
    vec4 u1;
    vec4 u2;
    vec4 u3;
    vec4 custom_uniforms[16];
    vec4 audio_bands;
    vec4 audio_history;
} ext;
#define alpha ext.u0.x
#define alpha_b ext.custom_uniforms[1].x
#define alpha_g ext.custom_uniforms[0].w
#define alpha_r ext.custom_uniforms[0].z
#define alpha_value ext.custom_uniforms[0].y
#define index_value ext.custom_uniforms[2].x
#define restore_black ext.custom_uniforms[2].y
#define time_f ext.u2.y
#define value_alpha_b ext.custom_uniforms[1].w
#define value_alpha_g ext.custom_uniforms[1].z
#define value_alpha_r ext.custom_uniforms[1].y

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;




uniform vec4 optx;
uniform vec4 random_var;


uniform mat4 mv_matrix;
uniform mat4 proj_matrix;
layout(set = 0, binding = 0) uniform sampler2D samp;
uniform sampler2D mat_samp;





vec4 xor_RGB(vec4 icolor, vec4 src) {
    ivec4 isource = ivec4(src * 255);
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
    vec4 color2 = texture(samp, tc / 2);
    vec4 color3 = texture(samp, tc/ 4);
    vec4 color4 = texture(samp, tc/ 8);
    color = (color * 0.3) + (color2 * 0.3) + (color3 * 0.3) + (color4 * 0.3) ;
    color = (0.5 * color) + (0.5 * texture(mat_samp, tc)) * alpha;
    
    vec4 fcolor = xor_RGB(texture(samp, tc), texture(mat_samp, tc));
    color = (0.5 * color) + (0.5 * fcolor);
    
}

