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
    float trailLength = 1.0;
    float trailOffset = 0.05 * pingPong(time_f, trailLength);
    vec2 offset = vec2(sin(time_f), cos(time_f)) * trailOffset;
    vec4 shadowColor = texture(samp, tc - offset);
    vec4 currentColor = texture(samp, tc);
    color = mix(currentColor, shadowColor, 0.5);
}
