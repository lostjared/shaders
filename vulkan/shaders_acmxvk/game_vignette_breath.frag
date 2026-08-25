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

// Slowly breathing vignette - emphasizes screen center, very gentle.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec3 c = texture(samp, tc).rgb;
    vec2 v = tc - 0.5;
    float r = dot(v, v);
    float breath = 1.05 + 0.10 * sin(time_f * 0.6);
    float vig = smoothstep(0.85, 0.10, r * breath);
    c *= mix(0.55, 1.0, vig);
    color = vec4(c, 1.0);
}
