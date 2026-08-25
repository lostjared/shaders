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
    vec2 normCoord = (tc * 2.0 - 1.0) * vec2(iResolution.x / iResolution.y, 1.0);
    normCoord.y = abs(normCoord.y);
    float dist = length(normCoord);
    float angle = atan(normCoord.y, normCoord.x);
    float spiralAmount = sin(time_f);
    angle += spiralAmount;
    dist = mix(dist, 1.0 - dist, sin(spiralAmount * 0.5));
    vec2 spiralCoord = vec2(cos(angle), sin(angle)) * dist;
    float scale = 1.0 + sin(spiralAmount * 0.2) * 0.5;
    spiralCoord *= scale;
    spiralCoord = (spiralCoord / vec2(iResolution.x / iResolution.y, 1.0) + 1.0) / 2.0;
    color = texture(samp, spiralCoord);
}
