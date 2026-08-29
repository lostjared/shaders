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

// High-contrast film noir black & white.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float lum = dot(c, vec3(0.30, 0.62, 0.08));
    lum = (lum - 0.5) * 1.45 + 0.5;
    lum = clamp(lum, 0.0, 1.0);
    vec2 v = tc - 0.5;
    float vig = 1.0 - dot(v, v) * 1.4;
    color = vec4(vec3(lum) * vig, 1.0);
}
