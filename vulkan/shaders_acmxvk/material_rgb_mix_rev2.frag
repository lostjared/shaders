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



in float timeval;

uniform vec4 optx;
uniform vec4 random_var;

uniform mat4 mv_matrix;
uniform mat4 proj_matrix;
layout(set = 0, binding = 0) uniform sampler2D samp;
uniform sampler2D mat_samp;



in vec2 iResolution_;



vec4 shift_vec(vec4 inputv, int dir) {
    vec4 rev;
    if(dir == 1) {
        rev[0] = inputv[2];
        rev[1] = inputv[0];
        rev[2] = inputv[1];
    } else {
        rev[0] = inputv[1];
        rev[1] = inputv[2];
        rev[2] = inputv[0];
    }
    return rev;
}

float random (vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}

void main(void)
{
    color = texture(samp, tc);
    vec4 color2;
    color2 = texture(mat_samp, tc);
    vec4 color3 = texture(samp, tc/2);
    vec4 color4 = texture(mat_samp, tc/2);
    vec2 st = (gl_FragCoord.xy / iResolution_.xy) + timeval;

    float r = random(st);
    int x1 = 0, x2 = 0;
    
    if(r < 0.5) {
        x1 = 1;
        x2 = 0;
    } else {
        x1 = 0;
        x2 = 1;
    }
    
    if(int(alpha_r)%2 == 0) {
        color = (shift_vec(color,x1) * 0.3) + (color2 * 0.3) + (shift_vec(color3,x2) * 0.5);
        
    } else {
        color = (color * 0.3) + (shift_vec(color3, x2) * 0.5) + (color4 * 0.5);
    }
}

