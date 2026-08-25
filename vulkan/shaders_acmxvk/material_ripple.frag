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
    float rippleRadius = 0.15 * sin(time_f * 1.5) + 0.2;
    float rippleDist = length(uv - vec2(0.5, 0.5));
    float ripple = sin(rippleDist * 20.0 - time_f * 4.0) * exp(-rippleRadius * rippleDist);

    vec2 rippleUV = uv + normalize(uv - vec2(0.5, 0.5)) * ripple * 0.025;

    float waterAmount = 0.1 * sin(time_f * 2.0 + uv.x * 5.0);
    vec2 waterUV = vec2(uv.x, uv.y + waterAmount);

    vec4 texColor1 = texture(samp, rippleUV);
    vec4 texColor2 = texture(mat_samp, rippleUV);
    float mixFactor = 0.5 + 0.5 * sin(time_f);
    vec4 finalColor = mix(texColor1, texColor2, 0.5);

    color = finalColor;
}
