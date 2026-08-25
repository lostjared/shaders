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
#define alpha_value ext.custom_uniforms[0].y
#define time_f ext.u2.y

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;

layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void)
{
    color = texture(samp, tc);
    ivec3 source;
    for(int i = 0; i < 3; ++i) {
        source[i] = int(255 * color[i]);
    }
    vec2 cord1 = vec2(tc[0]/2, tc[1]/2);
    vec2 cord2 = vec2(tc[0]/4, tc[1]/4);
    vec2 cord3 = vec2(tc[0]/8, tc[1]/8);
    vec4 col1 = texture(samp, cord1);
    vec4 col2 = texture(samp, cord2);
    vec4 col3 = texture(samp, cord3);
    color[0] = color[0] * col1[0];
    color[1] = color[1] * col2[1];
    color[2] = color[2] * col3[2];
    ivec3 int_color;
    for(int i = 0; i < 3; ++i) {
        int_color[i] = int(255 * color[i]);
        int_color[i] = int_color[i]^source[i];
        if(int_color[i] > 255)
            int_color[i] = int_color[i]%255;
        color[i] = float(int_color[i])/255;
    }
}


