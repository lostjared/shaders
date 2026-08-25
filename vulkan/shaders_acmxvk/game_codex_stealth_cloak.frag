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

// Stealth cloak: glassy displacement with desaturated shimmer.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec2 p = tc - 0.5;
    float wave = sin(p.y * 70.0 + time_f * 5.0) * sin(p.x * 43.0 - time_f * 3.0);
    vec2 uv = tc + vec2(wave * 0.012, cos(p.x * 55.0 + time_f * 4.0) * 0.006);
    vec3 c = texture(samp, clamp(uv, 0.0, 1.0)).rgb;
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    float veil = smoothstep(0.65, 0.05, dot(p, p));
    c = mix(c, vec3(lum) * vec3(0.65, 0.9, 1.0), veil * 0.55);
    c += vec3(0.15, 0.5, 0.8) * abs(wave) * veil;
    color = vec4(c, 1.0);
}
