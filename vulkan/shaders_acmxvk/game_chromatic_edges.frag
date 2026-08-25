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

// Lens chromatic aberration that grows toward the edges of the frame.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec2 v = tc - 0.5;
    float r2 = dot(v, v);
    float k = r2 * 0.04;
    vec2 dir = v;
    float cr = texture(samp, tc + dir * k * 1.0).r;
    float cg = texture(samp, tc                 ).g;
    float cb = texture(samp, tc - dir * k * 1.0).b;
    color = vec4(cr, cg, cb, 1.0);
}
