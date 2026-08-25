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

in vec3 vNormal;
layout(set = 0, binding = 0) uniform sampler2D samp;
layout(location = 0) out vec4 color;

void main() {
    const float PI = 3.141592653589793;
    vec3 n = normalize(vNormal);
    float u = atan(n.z, n.x) / (2.0 * PI) + 0.5;
    float v = acos(clamp(n.y, -1.0, 1.0)) / PI;
    color = texture(samp, vec2(u, v));
}