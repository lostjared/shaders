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

layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec2 uv = tc;
    vec2 center = vec2(0.5, 0.5) * iResolution / vec2(iResolution.y);
    vec2 pos = uv - center;
    pos *= 2.0;
    float angle = time_f;
    float cosA = cos(angle);
    float sinA = sin(angle);
    mat2 rot = mat2(cosA, -sinA, sinA, cosA);
    pos = rot * pos;
    float depth = mod(pos.x + pos.y, 0.5) - 0.25;
    float height = sin(depth * 3.14159) * 0.25; // Sin wave for a wavy effect
    vec3 baseColor = vec3(0.5 + 0.5 * sin(time_f), 0.5 + 0.5 * sin(time_f + 2.0), 0.5 + 0.5 * sin(time_f + 4.0));
    float light = 0.5 + 0.5 * sin(depth * 3.14159 + time_f);
    vec3 color3D = height * light * baseColor;
    color3D = sin(color3D * time_f);
    vec4 texColor = texture(samp, uv);
    color = mix(texColor, vec4(color3D, 1.0), 0.3);
}
