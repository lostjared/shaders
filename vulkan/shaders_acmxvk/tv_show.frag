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



float noise(float x) {
    return fract(sin(x) * 43758.5453);
}

void main(void) {
    vec2 uv = tc;

    vec2 center = uv - 0.5;
    uv = uv + center * (0.02 * sin(time_f * 1.5));

    float timeBasedNoise = noise(time_f * 10.0) * 0.05;
    float spatialNoise = noise(uv.y * 10.0 + time_f * 5.0) * 0.05;
    float combinedNoise = timeBasedNoise + spatialNoise;

    vec3 texColor = texture(samp, uv).rgb;
    float gray = dot(texColor, vec3(0.299, 0.587, 0.114));
    texColor = vec3(gray);

    texColor = texColor * (1.0 - combinedNoise);

    color = vec4(texColor, 1.0);
}
