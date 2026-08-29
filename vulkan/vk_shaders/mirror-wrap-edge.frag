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
#define time_f ext.u2.y

layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;


void main() {
    vec2 p = tc - 0.5;

    float r = max(abs(p.x), abs(p.y)) * 2.0;
    float w = 1.0 - smoothstep(0.7, 1.0, r);
    w *= w;

    float a = time_f * 0.8 * w;
    float c = cos(a);
    float s = sin(a);

    vec2 q = vec2(p.x * c - p.y * s,
                  p.x * s + p.y * c) + 0.5;

    vec2 uv = 1.0 - abs(1.0 - 2.0 * q);
    uv = fract(uv);

    color = texture(samp, uv);
}
