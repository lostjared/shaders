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

// Slow gentle wobble. Useful for drunk/dazed status effects.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec2 uv = tc;
    uv.x += sin(time_f * 1.7 + uv.y * 6.0) * 0.006;
    uv.y += cos(time_f * 1.3 + uv.x * 5.0) * 0.006;
    vec3 c = texture(samp, uv).rgb;
    color = vec4(c, 1.0);
}
