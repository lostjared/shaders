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

layout(location = 0) in vec2 tc; // Texture coordinates
layout(location = 0) out vec4 color; // Output color
layout(set = 0, binding = 0) uniform sampler2D samp; // Scene texture



void main() {
    vec2 uv = tc;
    vec2 reflectedUV = vec2(uv.x, uv.y);
    float waveAmplitude = 0.5;
    float waveFrequency = 3.0;
    float waveSpeed = 2.0;
    reflectedUV.y += sin(reflectedUV.x * waveFrequency + time_f * waveSpeed) * waveAmplitude;

    reflectedUV = clamp(reflectedUV, 0.0, 1.0);
    vec4 reflectedColor = texture(samp, reflectedUV);
    color = reflectedColor;
}
