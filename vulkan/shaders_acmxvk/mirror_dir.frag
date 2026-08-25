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
#define time_f ext.u2.y

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;


void main(void)
{
    vec2 mirrored_tc = tc;
    
    int direction = int(mod(time_f, 4.0));
    
    if (direction == 0) {
        mirrored_tc = tc;
    } else if (direction == 1) {
        mirrored_tc.x = 1.0 - tc.x;
    } else if (direction == 2) {
        mirrored_tc.y = 1.0 - tc.y;
    } else if (direction == 3) {
        mirrored_tc = 1.0 - tc;
    }

    color = texture(samp, mirrored_tc);
}

