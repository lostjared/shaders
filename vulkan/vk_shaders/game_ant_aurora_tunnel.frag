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

// Aurora tunnel — soft northern-lights vignette around frame edges.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec3 c = texture(samp, tc).rgb;
    vec2 p = tc - 0.5;
    float r = length(p);
    float edge = smoothstep(0.20, 0.75, r);
    float wave = sin(atan(p.y, p.x) * 3.0 + time_f * 0.5) * 0.5 + 0.5;
    vec3 aurora = mix(vec3(0.10, 0.95, 0.55), vec3(0.55, 0.30, 1.05), wave);
    c = mix(c, c + aurora, edge * 0.55);
    color = vec4(c, 1.0);
}
