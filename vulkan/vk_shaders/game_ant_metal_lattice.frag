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

// Metal lattice — faint moving grid lattice overlay.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec3 c = texture(samp, tc).rgb;
    vec2 p = tc * iResolution / 24.0 + vec2(time_f * 0.05, 0.0);
    vec2 g = abs(fract(p) - 0.5);
    float line = min(g.x, g.y);
    float lattice = smoothstep(0.08, 0.0, line) * 0.45;
    color = vec4(c + vec3(0.4, 0.75, 1.05) * lattice, 1.0);
}
