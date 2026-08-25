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

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;


float pingPong(float x, float length) {
    float modVal = mod(x, length * 2.0);
    return modVal <= length ? modVal : length * 2.0 - modVal;
}


void main(void) {
    float time_t =   pingPong(time_f, 10.0) + 2.0;
    vec2 uv = tc - 0.5;
    float len = length(uv);
    float factor = sqrt(len) * 0.5;
    uv *= (1.0 + sin(factor * time_t));
    color = texture(samp, uv + 0.5);
}
