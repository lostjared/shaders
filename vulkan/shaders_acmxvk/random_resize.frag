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

vec2 resizeVertical(vec2 uv, float blockSize, float timeFactor) {
    float blockHeight = blockSize;
    float offset = sin(time_f * timeFactor + uv.x * 10.0) * 0.05;
    uv.y += step(mod(uv.y, blockHeight), blockHeight * 0.5) * offset;
    return fract(uv);
}

vec2 randomShift(vec2 uv, float intensity) {
    float shiftX = rand(uv) * intensity * cos(time_f * 2.0);
    float shiftY = rand(uv + vec2(1.0, 1.0)) * intensity * sin(time_f * 2.0);
    return uv + vec2(shiftX, shiftY);
}

void main() {
    vec2 uv = tc;
    float blockSize = 0.1;
    uv = resizeVertical(uv, blockSize, 5.0);
    if (rand(floor(uv / blockSize)) > 0.5) {
        uv = randomShift(uv, 0.02);
    }
    vec4 texColor = texture(samp, fract(uv));
    vec3 glitchColor = texColor.rgb * (1.0 + 0.3 * sin(time_f * 10.0 + uv.y * 50.0));
    color = mix(texColor, vec4(glitchColor, texColor.a), 0.5);
}

