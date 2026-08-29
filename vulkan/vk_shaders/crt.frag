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
    vec2 uv = tc;
    vec2 center = uv - 0.5;
    uv = uv + center * (0.1 * length(center));
    float scanline = sin(uv.y * iResolution.y * 0.75) * 0.05;
    vec3 offset = vec3(0.001, -0.001, 0.0) * scanline;
    vec3 texColor;
    texColor.r = texture(samp, uv + vec2(offset.r, 0.0)).r;
    texColor.g = texture(samp, uv + vec2(0.0, offset.g)).g;
    texColor.b = texture(samp, uv + vec2(0.0, offset.b)).b;
    texColor *= (1.0 - scanline);
    color = vec4(texColor, 1.0);
}