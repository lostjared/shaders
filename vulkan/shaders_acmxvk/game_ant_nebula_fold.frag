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

// Nebula fold — folded color washes drifting across, gentle.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec3 c = texture(samp, tc).rgb;
    vec2 p = tc - 0.5;
    p = abs(p);
    float n = sin(p.x * 6.0 + p.y * 4.0 + time_f * 0.25);
    n = n * 0.5 + 0.5;
    vec3 neb = mix(vec3(0.20, 0.55, 1.10), vec3(1.05, 0.30, 0.70), n);
    color = vec4(c + neb * 0.40, 1.0);
}
