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
    vec2 center = iResolution / 2.0;
    vec2 uv = tc * iResolution;
    float distanceFromCenter = length(uv - center);

    float rippleSpeed = 2.0;
    float rippleFrequency = 20.0;

    float time = time_f * rippleSpeed;
    float wave = sin(pingPong(distanceFromCenter + time, rippleFrequency));

    float warpStrength = 0.05;
    float warpFrequency = 5.0;
    vec2 warp = vec2(sin(uv.y * warpFrequency + time), sin(uv.x * warpFrequency + time)) * warpStrength;

    vec2 rippleUV = tc + normalize(uv - center) * wave * 0.01 + warp;

    color = texture(samp, rippleUV);
}
