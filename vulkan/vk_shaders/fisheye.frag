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

void main(void) {
    vec2 center = vec2(0.5, 0.5);
    float strength = 0.5 + sin(time_f) * 0.5 * 8.0;
    vec2 tcFromCenter = tc - center;
    float distance = length(tcFromCenter);
    float angle = atan(tcFromCenter.y, tcFromCenter.x);
    float radius = distance * (1.0 + strength * (distance * distance));
    vec2 distortedTC = center + vec2(cos(angle), sin(angle)) * radius;
    distortedTC = clamp(distortedTC, 0.0, 1.0);
    color = texture(samp, distortedTC);
}
