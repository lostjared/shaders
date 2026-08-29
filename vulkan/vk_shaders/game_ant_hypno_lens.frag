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

// Hypno lens — very mild radial barrel + brightness ring (gameplay-safe).
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec2 p = tc - 0.5;
    float r = length(p);
    float k = 1.0 + 0.14 * r * r;
    vec2 uv = p / k + 0.5;
    vec3 c = texture(samp, uv).rgb;
    float ring = sin(r * 22.0 - time_f * 0.8) * 0.5 + 0.5;
    ring = smoothstep(0.65, 1.0, ring) * smoothstep(0.6, 0.1, r);
    c += vec3(0.7, 0.55, 1.10) * ring * 0.45;
    color = vec4(c, 1.0);
}
