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


vec4 multiLevelBlend(vec2 tc, sampler2D tex) {
    vec2 cord1 = vec2(tc.x / 2.0, tc.y / 2.0);
    vec2 cord2 = vec2(tc.x / 4.0, tc.y / 4.0);
    vec2 cord3 = vec2(tc.x / 8.0, tc.y / 8.0);
    vec4 col1 = texture(tex, cord1);
    vec4 col2 = texture(tex, cord2);
    vec4 col3 = texture(tex, cord3);
    return vec4(col1.r + col2.r, col1.g + col2.g, col1.b + col3.b, 1.0);
}

void main(void) {
    vec2 normCoord = tc;

    float distortionStrength = 0.02;
    float distortionFrequency = 15.0;
    float distortion1 = sin(normCoord.y * distortionFrequency + time_f) * distortionStrength;
    float distortion2 = cos((normCoord.x + normCoord.y) * distortionFrequency + time_f) * distortionStrength;
    vec2 distortedTC = normCoord + vec2(distortion1, distortion2);

    vec4 baseColor = texture(samp, distortedTC);
    vec4 blendedColor = multiLevelBlend(distortedTC, samp);

    float val = (blendedColor.r + blendedColor.g + blendedColor.b) * 0.5;
    for (int q = 0; q < 3; ++q) {
        blendedColor[q] *= sin(val * blendedColor[q] / 0.3);
    }

    color = (0.5 * blendedColor) + (0.5 * baseColor);
}

