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
in vec4 random_value;
uniform vec4 random_var;

uniform mat4 mv_matrix;
uniform mat4 proj_matrix;
layout(set = 0, binding = 0) uniform sampler2D samp;





uniform vec4 inc_valuex;
uniform vec4 inc_value;

void main(void)
{
    float time = time_f * 0.2;
    vec2 glitchOffset = vec2(sin(time * 2.0) * 0.005, cos(time * 3.0) * 0.005);
    glitchOffset += vec2(random_value.x * 0.005, random_value.y * 0.005);
    
    vec2 tcOffset = tc + glitchOffset;
    
    vec4 baseColor = texture(samp, tcOffset);
    vec4 glitchColor = texture(samp, tc + glitchOffset * 2.0);
    
    color = mix(baseColor, glitchColor, 0.5);
    color.rgb *= vec3(1.0 + sin(time_f * 5.0) * 0.1, 1.0 + cos(time_f * 5.0) * 0.1, 1.0 + sin(time_f * 7.0) * 0.1);
}
