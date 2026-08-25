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
    float len = length(uv);
    float bubble = smoothstep(0.8, 1.0, 1.0 - len);
    vec2 distort = uv * (1.0 + 0.1 * sin(time_f + len * 20.0));
    vec4 texColor = texture(samp, distort * 0.5 + 0.5);
    color = mix(texColor, vec4(1.0, 1.0, 1.0, 1.0), bubble);
}
