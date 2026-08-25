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

// Crispness boost via 5-tap unsharp mask. Great for upscaled retro content.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec2 px = 1.0 / iResolution;
    vec3 c  = texture(samp, tc).rgb;
    vec3 n  = texture(samp, tc + vec2(0.0,  px.y)).rgb;
    vec3 s  = texture(samp, tc + vec2(0.0, -px.y)).rgb;
    vec3 e  = texture(samp, tc + vec2( px.x, 0.0)).rgb;
    vec3 w  = texture(samp, tc + vec2(-px.x, 0.0)).rgb;
    vec3 sharp = c * 5.0 - (n + s + e + w);
    vec3 outc = mix(c, sharp, 0.35);
    color = vec4(clamp(outc, 0.0, 1.0), 1.0);
}
