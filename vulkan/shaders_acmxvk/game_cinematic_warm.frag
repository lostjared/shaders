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

// Hollywood teal-and-orange grade with mild contrast lift.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec3 c = texture(samp, tc).rgb;
    c = (c - 0.5) * 1.12 + 0.5;
    vec3 shadows = mix(c, c * vec3(0.85, 1.00, 1.15), smoothstep(0.4, 0.0, dot(c, vec3(0.333))));
    vec3 highs   = mix(shadows, shadows * vec3(1.18, 1.05, 0.85), smoothstep(0.5, 1.0, dot(c, vec3(0.333))));
    color = vec4(clamp(highs, 0.0, 1.0), 1.0);
}
