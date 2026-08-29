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


void main(void) {
    float distortionStrength = 0.02;
    float distortionFrequency = 15.0;
    float distortion1 = sin(tc.y * distortionFrequency + time_f) * distortionStrength;
    float distortion2 = cos((tc.x + tc.y) * distortionFrequency + time_f) * distortionStrength;

    vec2 distortedTC1 = tc + vec2(distortion1, distortion2);
    vec2 distortedTC2 = tc + vec2(distortion2, -distortion1);

    vec4 texColor1 = texture(samp, distortedTC1);
    vec4 texColor2 = texture(samp, distortedTC2);

    color = texColor2;
}

