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

// Toxic / radiation green wash with subtle vignette pulse.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    c = mix(c, vec3(lum) * vec3(0.55, 1.00, 0.55), 0.45);
    vec2 v = tc - 0.5;
    float pulse = 0.5 + 0.5 * sin(time_f * 1.5);
    c *= mix(0.7, 1.0, smoothstep(0.55, 0.05, dot(v, v) * (1.0 + 0.15 * pulse)));
    color = vec4(c, 1.0);
}
