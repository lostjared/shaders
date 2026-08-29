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

// Gem polar — slight polar-coordinate sheen rotating slowly (no warp).
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec3 c = texture(samp, tc).rgb;
    vec2 p = tc - 0.5;
    p.x *= iResolution.x / iResolution.y;
    float a = atan(p.y, p.x) + time_f * 0.3;
    float r = length(p);
    float spoke = sin(a * 5.0) * 0.5 + 0.5;
    float mask = smoothstep(0.7, 0.0, r);
    vec3 tint = mix(vec3(0.65, 0.40, 1.10), vec3(0.30, 0.95, 1.10), spoke);
    color = vec4(c + tint * mask * 0.40, 1.0);
}
