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

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;


const float PI = 3.14159265359;

void main() {
    float aspect = iResolution.x / max(iResolution.y, 1.0);
    vec2 p = (tc - 0.5) * vec2(aspect, 1.0);
    float radius = length(p);
    float sector = 2.0 * PI / 12.0;
    float angle = abs(mod(atan(p.y, p.x) + 0.5 * sector, sector) - 0.5 * sector);
    p = radius * vec2(cos(angle), sin(angle));
    vec2 uv = p / vec2(aspect, 1.0) + 0.5;
    color = texture(samp, uv);
}
