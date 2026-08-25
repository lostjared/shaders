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
    float time_t = pingPong(time_f, 10.0) + 2.0;
    float foldAmount = sin(time_t) * 0.5 + 0.5;
    vec2 uv = tc;

    if (uv.x > foldAmount) {
        float offset = (uv.x - foldAmount) / (1.0 - foldAmount);
        uv.x = foldAmount + offset * foldAmount;
    }

    color = texture(samp, uv);
}
