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

// Cyberpunk grade: magenta shadows, cyan highlights, subtle bloom.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec2 px = 1.0 / iResolution;
    vec3 c  = texture(samp, tc).rgb;
    vec3 b  = texture(samp, tc + px * 2.0).rgb;
    vec3 d  = texture(samp, tc - px * 2.0).rgb;
    vec3 bloom = max(c, max(b, d)) - 0.6;
    bloom = max(bloom, 0.0);
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    vec3 shadow = vec3(0.45, 0.05, 0.55);
    vec3 highlight = vec3(0.10, 0.85, 0.95);
    vec3 graded = mix(shadow, highlight, smoothstep(0.0, 1.0, lum));
    c = mix(c, graded, 0.45) + bloom * vec3(1.2, 0.6, 1.4);
    color = vec4(c, 1.0);
}
