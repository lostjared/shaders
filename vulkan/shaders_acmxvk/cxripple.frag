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
    vec2 uv = tc - 0.5;
    float dist = length(uv);
    float ripple = sin(dist * 20.0 - time_f * 5.0);
    float angle = ripple + time_f * 2.0;
    float s = sin(angle);
    float c = cos(angle);
    vec2 offset = vec2(c, s) * ripple * 0.05;
    vec2 pattern = sin(fract(uv * 10.0 + offset) * time_f);
    float brightness = fract(pattern.x * pattern.y * 10.0);
    vec3 colorValue = vec3(0.5 + 0.5 * sin(10.0 * dist + time_f), 0.5 + 0.5 * cos(10.0 * dist + time_f), brightness);

    vec4 texColor = texture(samp, uv + 0.5 + offset);
    color = vec4(colorValue, 1.0) * texColor;
}
