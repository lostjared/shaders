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



void main() {
    vec2 uv = tc * 2.0 - 1.0;
    uv *= iResolution.y / iResolution.x;
    vec2 center = vec2(0.0, 0.0);
    vec2 offset = uv - center;
    float dist = length(offset);
    float angle = atan(offset.y, offset.x);

    float ripple = sin(dist * 30.0 - time_f * 10.0) * 0.05;
    float spiral = sin(angle * 5.0 + time_f) * 0.05;
    float wave = sin(uv.x * 10.0 + time_f) * 0.03;

    vec2 warpedUV = uv + normalize(offset) * ripple;
    warpedUV += vec2(cos(angle), sin(angle)) * spiral;
    warpedUV.y += wave;

    vec4 texColor = texture(samp, warpedUV * 0.5 + 0.5);
    float shimmer = sin(dist * 10.0 + time_f * 5.0) * 0.1 + 0.9;
    vec3 finalColor = texColor.rgb * shimmer;

    color = vec4(finalColor, texColor.a);
}

