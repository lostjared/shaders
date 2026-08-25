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




in vec3 vpos;
uniform vec4 optx;
uniform vec4 random_var;

uniform mat4 mv_matrix;
uniform mat4 proj_matrix;
layout(set = 0, binding = 0) uniform sampler2D samp;
uniform sampler2D mat_samp;




in vec2 iResolution_;

vec4 color_blend(vec4 color) {
    vec4 color2 = color;
    ivec4 color_source = ivec4(color * 255);
    color = color*alpha;
    ivec4 colori = ivec4(color * 255);
    for(int i = 0; i < 3; ++i) {
        if(colori[i] >= 255)
            colori[i] = colori[i]%255;
        
        if(color_source[i] >= 255)
            color_source[i] = color_source[i]%255;
        
        colori[i] = colori[i] ^ color_source[i];
        color[i] = float(colori[i])/255;
    }
    
    for(int i = 0; i < 3; ++i)
        if(color[i] < 0.2) color[i] = color2[i];
    return color;
}

void main(void)
{
    color = texture(samp, tc);
    ivec4 source = ivec4(255 * color);
    vec2 pos = gl_FragCoord.xy/iResolution_.xy;
    vec2 vpos;
    vpos[1] = 1.0-tc[1];
    vpos[0] = tc[0];
    vec4 color2 = texture(samp, vpos);
    vec4 color3 = texture(mat_samp, tc);
    vec4 color4 = texture(mat_samp, vpos);
    color = (0.3 * color) + (0.3 * color2) + (0.3 * color3) + (0.3 * color4);
    
    color = color_blend(color);
}

