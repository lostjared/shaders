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
#define iResolution ext.u0.zw
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



in vec2 iResolution_;



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
    ivec4 source = ivec4(color * 255);
    vec4 color2;
    vec2 pos = (gl_FragCoord.xy/iResolution_.xy);
    color2 = texture(mat_samp, tc);
 
    color[0] = (0.3 * color[0]) + (0.3 * color2[0]) + (0.2 * (pos[0]*(alpha/2)));
    color[1] = (0.3 * color[1]) + (0.3 * color2[0]) + (0.2 * (pos[1]*(alpha/2)));
    color[2] = (0.3 * color[2]) + (0.3 * color2[0]) + (0.2 * (pos[0]*(alpha/2)));
    
    color = (0.5 * color) + (0.3 *(color*alpha));
    
    color = xor_RGB(color, source);
}

