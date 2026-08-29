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

// Metal prism — gentle RGB chromatic split on edges of bright objects.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec2 p = tc - 0.5;
    float r = length(p);
    vec2 dir = p / max(r, 1e-4);
    float k = 0.0090 * smoothstep(0.0, 0.7, r);
    float rC = texture(samp, tc + dir * k).r;
    float gC = texture(samp, tc).g;
    float bC = texture(samp, tc - dir * k).b;
    color = vec4(rC, gC, bC, 1.0);
}
