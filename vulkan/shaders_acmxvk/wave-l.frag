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



void main() {
    
    vec2 pos = tc;
    
    float wave_x = sin((tc.x + time_f) * 5.0);
    float wave_y = cos((tc.y + time_f) * 8.0);

    pos.x += wave_x;
    pos.y += wave_y;
    color = texture(samp, sin(pos * time_f));
}
