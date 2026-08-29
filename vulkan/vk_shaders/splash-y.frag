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



void main(void)
{
    vec2 uv = tc;
    vec2 center = vec2(0.5, 0.5);
    float distance = length(uv - center);

    float ripple = sin(10.0 * distance - time_f * 3.0);
    ripple *= tan(time_f) / distance;

    uv += (uv - center) * ripple;

    color = texture(samp, uv);
    color = mix(color, vec4(0.0, 0.5, 1.0, 1.0), 0.2);
}
