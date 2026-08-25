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


void main(void){
    vec2 normCoord = tc;
    float tearLine = sin(time_f) * 0.5 + 0.5;
    float distFromTear = abs(normCoord.x - tearLine);
    float displacement = 0.202 * (1.0 - smoothstep(0.0, 0.1, distFromTear));
    normCoord.y += sin(displacement);
    color = texture(samp, normCoord);
}
