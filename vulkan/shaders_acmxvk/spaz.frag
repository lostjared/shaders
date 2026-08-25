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
    vec2 normCoord = (tc * 2.0 - 1.0);
    float distortionX = sin(normCoord.y * 10.0 + time_f * 3.0) * 0.05;
    float distortionY = cos(normCoord.x * 15.0 + time_f * 2.0) * 0.05;
    distortionX += sin(time_f * 5.0) * 0.02;
    distortionY += cos(time_f * 7.0) * 0.02;
    vec2 distortedCoord = normCoord + vec2(distortionX, distortionY);
    distortedCoord = (distortedCoord + 1.0) / 2.0;
    distortedCoord = clamp(distortedCoord, 0.0, 1.0);
    color = texture(samp, distortedCoord);
}
