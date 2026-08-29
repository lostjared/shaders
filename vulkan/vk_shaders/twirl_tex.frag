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

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;

layout(set = 0, binding = 0) uniform sampler2D samp;


void main(void) {
    vec2 center = vec2(0.5, 0.5);
    vec2 normCoord = tc - center;
    normCoord.x *= iResolution.x / iResolution.y;
    float distance = length(normCoord);
    float angle = atan(normCoord.y, normCoord.x);
    float twirlAmount = 5.0;
    angle += distance * twirlAmount * sin(time_f);
    vec2 twirledCoord = vec2(cos(angle), sin(angle)) * distance;
    twirledCoord.x *= iResolution.y / iResolution.x;
    color = texture(samp, twirledCoord + center);
}
