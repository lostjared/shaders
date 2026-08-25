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



void main() {
    vec2 uv = tc;
    float distortA = sin(time_f * 0.5) * 0.1;
    float distortB = cos(time_f * 0.5) * 0.1;

    vec2 uv1 = vec2(uv.x + distortA, uv.y + distortB);

    vec2 uv2 = vec2(uv.x - distortA, uv.y - distortB);

    vec4 texColor1 = texture(samp, tan(uv1));
    vec4 texColor2 = texture(mat_samp, sin(uv2));
    float mixFactor = 0.5 + 0.5 * sin(time_f * 0.7);
    vec4 mixedTexture = mix(texColor1, texColor2, mixFactor);
    color = mixedTexture;
}
