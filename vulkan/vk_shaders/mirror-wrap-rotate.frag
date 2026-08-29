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
    float a = time_f * 0.5;
    float c = cos(a);
    float s = sin(a);

    vec2 p = tc - 0.5;
    vec2 r = vec2(p.x * c - p.y * s,
                  p.x * s + p.y * c);
    vec2 uv = r + 0.5;

    uv = 1.0 - abs(1.0 - 2.0 * uv);
    uv = uv - floor(uv);

    color = texture(samp, uv);
}
