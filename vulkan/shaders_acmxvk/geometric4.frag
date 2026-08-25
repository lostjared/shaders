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
    vec2 uv = tc * iResolution / vec2(iResolution.y);
    float time = time_f * 0.5;
    float angle = time;
    vec2 center = vec2(0.5, 0.5) * iResolution / vec2(iResolution.y);
    vec2 toCenter = uv - center;
    float radius = length(toCenter);
    float theta = atan(toCenter.y, toCenter.x) + time;
    float pattern = abs(sin(12.0 * theta) * cos(12.0 * radius));
    vec4 texColor = texture(samp, tc);
    vec2 modUv = tc + (0.1 * pattern) * vec2(cos(theta), sin(theta));
    vec4 modTexColor = texture(samp, modUv);
    color = mix(texColor, modTexColor, pattern);
}
