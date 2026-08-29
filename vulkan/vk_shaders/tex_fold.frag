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
    float zoomFactor = 0.5 + 0.5 * sin(time_f);
    float angle = time_f;
    vec2 center = vec2(0.5, 0.5);
    vec2 dir = tc - center;
    float cosAngle = cos(angle);
    float sinAngle = sin(angle);
    vec2 rotatedTc = vec2(
        cosAngle * dir.x - sinAngle * dir.y,
        sinAngle * dir.x + cosAngle * dir.y
    ) * zoomFactor + center;
    color = texture(samp, rotatedTc);
}
