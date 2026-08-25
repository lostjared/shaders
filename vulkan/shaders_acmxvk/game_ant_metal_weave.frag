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

// Metal weave — interlocking diagonal weave pattern overlay.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec3 c = texture(samp, tc).rgb;
    vec2 p = tc * iResolution / 18.0;
    float w1 = sin((p.x + p.y) * 3.14159);
    float w2 = sin((p.x - p.y) * 3.14159);
    float weave = max(smoothstep(0.6, 1.0, w1), smoothstep(0.6, 1.0, w2)) * 0.40;
    color = vec4(c + vec3(0.95, 0.97, 1.10) * weave, 1.0);
}
