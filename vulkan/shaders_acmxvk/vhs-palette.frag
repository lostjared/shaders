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

void main(void) {
    vec4 texColor = texture(samp, tc);

    vec4 vhsColor = texColor;
    vhsColor.rgb = vhsColor.rgb * vec3(0.9, 0.85, 0.8) + vec3(0.1, 0.1, 0.15);
    vhsColor.rgb = clamp(vhsColor.rgb, 0.0, 1.0);

    color = vhsColor;
}
