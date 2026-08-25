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


float noise(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

void main(void) {
    vec2 uv = tc;
    float time = time_f * 0.5;
    float noiseValue = noise(uv * 10.0 + time);
    vec2 heatWaveOffset = vec2(noiseValue - 0.5, 0.0) * 0.02;
    vec2 nuv = uv + heatWaveOffset;
    vec4 texColor = texture(samp, nuv);
    color = texColor;
}

