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
#define time_f ext.u2.y

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;


void main(void) {
    vec2 uv = tc;
    float amplitude = sin(time_f) * 0.5 + 0.5;
    vec2 distortedUV = uv + vec2(sin(uv.y * 10.0 + time_f) * 0.1, cos(uv.x * 10.0 + time_f) * 0.1) * amplitude;
    color = texture(samp, distortedUV);
}
