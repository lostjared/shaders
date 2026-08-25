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
    vec2 uv = tc;
    float maxTime = pingPong(time_f, 10.0);
    float time = pingPong(time_f, maxTime);
    float gForceIntensity = 0.1;
    float waveFrequency = 10.0;
    float waveAmplitude = 0.03;
    float gravityPull = gForceIntensity * time * uv.y;
    float waveDistortion = waveAmplitude * sin(waveFrequency * uv.x + time * 2.0);
    vec2 centeredUV = uv - vec2(0.5, 0.5);
    float angle = time + length(centeredUV) * 4.0;
    float spiralAmount = 0.5 * (1.0 - uv.y);
    mat2 rotation = mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
    vec2 spiraledUV = rotation * centeredUV * (1.0 + spiralAmount);
    vec2 distortedUV = spiraledUV + vec2(0.5, 0.5);
    distortedUV.y += gravityPull + waveDistortion;
    distortedUV = clamp(distortedUV, vec2(0.0), vec2(1.0));
    color = texture(samp, distortedUV);
}
