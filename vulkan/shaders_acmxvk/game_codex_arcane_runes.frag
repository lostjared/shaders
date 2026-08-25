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

// Arcane runes: rotating sigils over the screen for spell-cast feedback.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec2 p = tc - 0.5;
    p.x *= iResolution.x / max(iResolution.y, 1.0);
    float r = length(p);
    float a = atan(p.y, p.x);
    float sigil = step(0.93, sin(a * 12.0 - time_f * 2.4) * 0.5 + 0.5);
    sigil *= smoothstep(0.015, 0.0, abs(r - 0.32));
    float inner = smoothstep(0.01, 0.0, abs(fract((a + time_f) * 2.0) - 0.5) - 0.47) * smoothstep(0.28, 0.05, r);
    vec3 c = texture(samp, tc).rgb;
    c += vec3(0.75, 0.22, 1.0) * min(1.0, sigil + inner) * 0.85;
    color = vec4(c, 1.0);
}
