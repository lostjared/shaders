// matrix
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
    float time_t = mod(time_f, 10.0);
    vec2 normCoord = (tc * 2.0 - 1.0) * vec2(iResolution.x / iResolution.y, 1.0);
    float refractionIndex = time_t * 0.5;
    float radius = 1.0 * tan(time_t);
    float distSquared = dot(normCoord, normCoord);
    normCoord *= 1.0 + refractionIndex * distSquared;
    vec2 coord = tan(normCoord * time_t) / vec2(iResolution.x / iResolution.y, 1.0) * 0.5 + 0.5;
    color = texture(samp, coord);
}
