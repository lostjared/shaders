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



void main(void) {
    vec2 uv = tc * 2.0 - 1.0;
    float dist = length(uv);
    float angle = atan(uv.y, uv.x);
    float centerSize = 0.5 + 0.4 * sin(time_f * 3.0);
    float bloomEffect = sin(time_f + dist * 6.0) * 0.5 + 0.5;

    vec2 centerUV = uv * mix(1.0, bloomEffect, 0.3);
    vec2 outerUV = uv * (1.0 + 0.5 * (1.0 - dist));

    centerUV = centerUV * 0.5 + 0.5;
    outerUV = outerUV * 0.5 + 0.5;

    vec4 centerColor = texture(samp, centerUV);
    vec4 outerColor = texture(samp, outerUV);

    float mixFactor = smoothstep(centerSize - 0.1, centerSize, dist);
    color = mix(centerColor, outerColor, mixFactor);
    color = mix(color, texture(samp, tc), 0.5);
}
