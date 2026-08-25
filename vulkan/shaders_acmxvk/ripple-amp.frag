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


float hash(float n) {
    return fract(sin(n) * 43758.5453123);
}

void main(void) {
    float yPos = gl_FragCoord.y / iResolution.y;
    float xPos = gl_FragCoord.x / iResolution.x;

    // Random phase per scanline
    float rndY = hash(floor(yPos * 200.0));
    float rndX = hash(floor(xPos * 150.0));

    // Faster wave motion
    float waveY = sin(yPos * (10.0 + rndY * 5.0) + time_f * (4.0 + rndX * 2.0));
    float waveX = cos(xPos * (8.0 + rndX * 4.0) + time_f * (3.0 + rndY * 2.0));

    // Slightly higher amplitude, with randomized modulation
    float amplitude = 0.025 + 0.015 * hash(floor(time_f * 0.5));
    vec2 offset = vec2(waveX, waveY) * amplitude;

    vec2 coord = clamp(tc + offset, 0.001, 0.999);
    color = texture(samp, coord);
}
