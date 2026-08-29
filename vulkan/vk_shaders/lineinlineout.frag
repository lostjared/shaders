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



void main() {
    vec2 uv = tc;
    float centerY = 0.5 + 0.25 * sin(time_f);
    float shiftAmount = 0.1 * sin(time_f);

    if (uv.y > centerY) {
        uv.x += shiftAmount;
    } else {
        uv.x -= shiftAmount;
    }

    vec4 baseColor = texture(samp, uv);
    color = baseColor;
}
