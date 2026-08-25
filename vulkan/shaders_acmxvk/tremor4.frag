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



float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

vec2 tremorEffect(vec2 uv, float baseFrequency, float baseAmplitude, float timeFactor) {
    float duration = mod(time_f, timeFactor);
    float frequency = baseFrequency * (1.0 + 0.5 * duration / timeFactor);
    float amplitude = baseAmplitude * (1.0 + 0.5 * duration / timeFactor);
    float tremorX = sin(uv.y * frequency + time_f * 10.0) * amplitude;
    float tremorY = cos(uv.x * frequency + time_f * 10.0) * amplitude;
    return uv + vec2(tremorX, tremorY);
}

void main() {
    vec2 uv = tc;
    float baseFrequency = 20.0;
    float baseAmplitude = 0.01;
    float timeFactor = 5.0;
    uv = tremorEffect(uv, baseFrequency, baseAmplitude, timeFactor);
    vec4 texColor = texture(samp, fract(uv));
    color = texColor;
}

