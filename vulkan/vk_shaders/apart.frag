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



vec2 pseudoRandomDirection(float time) {
    return normalize(vec2(sin(time * 1.3), cos(time * 1.7)));
}

void main(void) {
    vec2 centeredCoord = (tc * 2.0 - 1.0) * vec2(iResolution.x / iResolution.y, 1.0);

    float dist = length(centeredCoord);
    vec2 spiralDir = pseudoRandomDirection(time_f + dist * 5.0);     float angle = atan(centeredCoord.y, centeredCoord.x) + time_f * 2.0;
    float radius = dist * (1.0 + 0.1 * sin(time_f * 3.0 + dist * 10.0));
    vec2 spiralCoord = vec2(cos(angle), sin(angle)) * radius * 0.5 + spiralDir * 0.1 * sin(time_f * 2.0);
    
    spiralCoord = (spiralCoord / vec2(iResolution.x / iResolution.y, 1.0) + 1.0) / 2.0;

    color = texture(samp, spiralCoord);
}

