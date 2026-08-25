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

float pingPong(float x, float length) {
    float modVal = mod(x, length * 2.0);
    return modVal <= length ? modVal : length * 2.0 - modVal;
}

vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0/3.0, 1.0/3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void main(void) {
    float time_t = pingPong(time_f, 7.0);
    vec2 uv = tc * 2.0 - 1.0;
    float frequency = 10.0;
    float amplitude = 0.02;
    float waveX = sin(uv.y * frequency + time_t) * amplitude;
    waveX += sin(uv.y * frequency * 0.5 + time_t * 1.5) * amplitude * 0.5;
    float waveY = sin(uv.x * frequency + time_t * 0.8) * amplitude;
    waveY += sin(uv.x * frequency * 0.5 + time_t * 1.2) * amplitude * 0.5;
    uv += vec2(waveX, waveY);

    float hue = mod((uv.y + 1.0) * 0.5 + time_t * 0.1, 1.0);
    float saturation = 1.0;
    float value = 1.0;
    vec3 neonColor = hsv2rgb(vec3(hue, saturation, value));

    vec4 texColor = texture(samp, uv * 0.5 + 0.5);
    float depth = (uv.y + 1.0) * 0.5;
    float attenuation = mix(1.0, 0.6, depth);
    vec3 finalColor = mix(neonColor, sin(texColor.rgb * time_t), 0.5) * attenuation;

    color = vec4(finalColor, 1.0);
}
