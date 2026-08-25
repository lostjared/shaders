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



mat2 rotate(float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return mat2(c, -s, s, c);
}

vec2 mirror(vec2 uv) {
    return abs(mod(uv, 2.0) - 1.0);
}

void main() {
    vec2 uv = tc * iResolution.xy;
    vec2 sectionSize = vec2(100.0);
    vec2 sectionIndex = floor(uv / sectionSize);
    vec2 localUV = mod(uv, sectionSize) / sectionSize;
    float angle = time_f + length(sectionIndex) * 0.5;
    localUV = rotate(angle) * (localUV - 0.5) + 0.5;
    localUV = mirror(localUV);
    vec2 texCoord = (sectionIndex + localUV) * sectionSize / iResolution.xy;
    color = texture(samp, texCoord);
}

