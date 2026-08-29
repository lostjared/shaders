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

vec2 glitchOffset(vec2 uv, float intensity) {
    float glitchX = rand(uv) * intensity * sin(time_f);
    float glitchY = rand(uv + vec2(1.0, 1.0)) * intensity * cos(time_f);
    return uv + vec2(glitchX, glitchY);
}

void main() {
    vec2 uv = tc;
    float blockSize = 0.1;
    vec2 blockCoord = floor(uv / blockSize);
    vec2 localCoord = fract(uv / blockSize);
    float randomSeed = rand(blockCoord);
    if (randomSeed > 0.5) {
        uv = glitchOffset(uv, 0.05);
    }
    vec3 texColor = texture(samp, uv).rgb;
    vec3 glitchColor = texColor * (1.0 + 0.5 * sin(time_f * 10.0 + randomSeed * 6.28));
    color = mix(vec4(texColor, 1.0), vec4(glitchColor, 1.0), 0.5);
}

