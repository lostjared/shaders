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

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main() {
    vec2 uv = tc;

    float blockSize = 0.1 + 0.05 * sin(time_f * 2.0);
    float blockY = floor(uv.y / blockSize) * blockSize;

    vec2 resizedUV = vec2(uv.x, blockY + mod(uv.y, blockSize) * (0.5 + 0.5 * sin(time_f + blockY * 10.0)));

    vec4 texColor = texture(samp, resizedUV);
    color = texColor;
}

