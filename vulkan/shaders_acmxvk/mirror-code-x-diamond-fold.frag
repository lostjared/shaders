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

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;

void main() {
    vec2 p = abs(tc - 0.5);
    if (p.y > p.x) {
        p = p.yx;
    }
    vec2 uv = p + 0.5;
    color = texture(samp, uv);
}
