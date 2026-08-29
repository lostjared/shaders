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
#define iMouse ext.mouse
#define iResolution ext.u0.zw
#define time_f ext.u2.y

layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;




void main(void) {
    vec2 m = (iMouse.z > 0.5) ? (iMouse.xy / iResolution) : vec2(0.5);
    vec2 d = tc - m;
    float r = length(d);
    vec2 dir = d / max(r, 1e-6);

    float waveLength = 0.05;
    float amplitude = 0.02;
    float speed = 2.0;

    float ripple = sin((r / waveLength - time_f * speed) * 6.2831853);
    vec2 uv = tc + dir * ripple * amplitude;

    color = texture(samp, uv);
}
