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
    float trailLength = sin(8.0 * time_f);
    vec4 currentColor = texture(samp, tc);

    vec4 shadowColor1 = texture(samp, tc - vec2(sin(time_f), cos(time_f)) * 0.02 * pingPong(time_f, trailLength));
    vec4 shadowColor2 = texture(samp, tc - vec2(sin(time_f + 1.0), cos(time_f + 1.0)) * 0.04 * pingPong(time_f + 1.0, trailLength));
    vec4 shadowColor3 = texture(samp, tc - vec2(sin(time_f + 2.0), cos(time_f + 2.0)) * 0.06 * pingPong(time_f + 2.0, trailLength));

    vec4 shadowColor = (shadowColor1 + shadowColor2 + shadowColor3) / 3.0;

    color = mix(currentColor, shadowColor, 0.5);
}
