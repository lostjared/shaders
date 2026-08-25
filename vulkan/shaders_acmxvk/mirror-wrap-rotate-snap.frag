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
    float raw = time_f * 0.5;
    float step = 1.57079632679;
    float a = round(raw / step) * step;
    float c = cos(a);
    float s = sin(a);

    vec2 p = tc - 0.5;
    vec2 uv = vec2(p.x * c - p.y * s,
                   p.x * s + p.y * c) + 0.5;

    uv = abs(fract(uv) * 2.0 - 1.0);

    color = texture(samp, uv);
}
