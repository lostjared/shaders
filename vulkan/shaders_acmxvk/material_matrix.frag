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
uniform sampler2D mat_samp;


void main(void) {
    vec2 uv = tc;
   float blockSize = 4.0 + 60.0 * abs(sin(time_f));

    vec2 blockUV = floor(uv * iResolution / blockSize) * blockSize / iResolution;

    vec4 color1 = texture(samp, blockUV);
    vec4 color2 = texture(mat_samp, blockUV);

    float mixFactor = 0.5 + 0.5 * sin(time_f * 3.14159);
    vec4 mixedColor = mix(color1, color2, mixFactor);

    color = mixedColor;
}
