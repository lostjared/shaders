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

layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;

void main(void) {
    vec3 col = texture(samp, tc).rgb;
    
    if(col.r < 0.3 && col.g < 0.3 && col.b < 0.3)
        color = vec4(1.0, 0.0, 0.0, 1.0);
    else
        color = vec4(col, 1.0);
     
 }