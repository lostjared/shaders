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
#define iResolution ext.u0.zw
#define time_f ext.u2.y

layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    
    float loop_dur = 15.0;
    float current_t = mod(time_f, loop_dur);
 
    vec2 uv = (tc - 0.5) * (iResolution.x / iResolution.y, 1.0);
    float radius = length(uv) * current_t;
    vec2 coord = sin(tc*time_f * radius/2);
       
    
    color = texture(samp, coord);
}
