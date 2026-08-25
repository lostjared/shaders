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

float pingPong(float t, float maxT) {
    return abs(mod(t, 2.0 * maxT) - maxT);
}

vec2 tremorEffect(vec2 uv, float frequency, float maxAmplitude, float interval) {
    float intervalFactor = pingPong(time_f, interval) / interval;
    float amplitude = maxAmplitude * intervalFactor;
    float tremorX = sin(uv.y * frequency + time_f * 5.0) * amplitude;
    float tremorY = cos(uv.x * frequency + time_f * 5.0) * amplitude;
    return uv + vec2(tremorX, tremorY);
}

void main() {
    vec2 uv = tc;
    float frequency = 20.0;
    float maxAmplitude = 0.02;
    float interval = 2.0;
    uv = tremorEffect(uv, frequency, maxAmplitude, interval);
    vec4 texColor = texture(samp, fract(uv));
    color = texColor;
}

