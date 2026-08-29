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



float pingPong(float x, float length) {
    float modVal = mod(x, length * 2.0);
    return modVal <= length ? modVal : length * 2.0 - modVal;
}

void main(void) {
    vec2 center = vec2(0.5, 0.5);
    float angle = time_f;
    vec2 tc_centered = tc - center;
    float cos_theta = cos(angle);
    float sin_theta = sin(angle);
    vec2 tc_rotated;
    tc_rotated.x = tc_centered.x * cos_theta - tc_centered.y * sin_theta;
    tc_rotated.y = tc_centered.x * sin_theta + tc_centered.y * cos_theta;

    tc_rotated += center;
    vec4 texColor = texture(samp, tc_rotated);
    color = texColor;
}

