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

layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;

void main() {
    vec2 uv = fract(tc);
    uv = min(uv, 1.0 - uv) * 2.0; 
    uv = vec2(min(uv.x, uv.y), max(uv.x, uv.y));
    color = texture(samp, uv);
}