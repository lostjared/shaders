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




float pingPong(float x, float length) {
    float modVal = mod(x, length * 2.0);
    return modVal <= length ? modVal : length * 2.0 - modVal;
}

void main(void)
{
    float time_x = pingPong(time_f, 2.0) + 1.0;
    float time_y = pingPong(time_f, 4.0) + 1.0;
    float time_z = pingPong(time_f, 8.0) + 1.0;
    color = texture(samp, tc);
    vec4 color2 = texture(samp, tc /time_x);
    vec4 color3 = texture(samp, tc/time_y);
    vec4 color4 = texture(samp, tc/time_z);
    color = (color * 0.4) + (color2 * 0.4) + (color3 * 0.4) + (color4 * 0.4) ;
    float time_q = pingPong(time_f, 25.0);
    color = cos(sin(length(time_q) * color));
}

