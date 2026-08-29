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


void main(void)
{
    vec2 uv = tc * 2.0 - 1.0;
    float t = time_f * 0.5;
    float glitchX = sin(uv.y * 10.0 + t) * 0.1;
    float glitchY = cos(uv.x * 10.0 + t) * 0.1;
    vec2 glitchUV = vec2(uv.x + glitchX, uv.y + glitchY);
    float r = length(glitchUV);
    float a = atan(glitchUV.y, glitchUV.x);
    float radius = sin(t + r * 5.0) * 0.5 + 0.5;
    float angle = a + t + sin(r * 20.0 + t) * 0.1;
    vec2 distorted_uv = vec2(cos(angle), sin(angle)) * radius + 0.5;

    vec3 col = texture(samp, distorted_uv).rgb;
    
    col = mix(col, vec3(1.0, 0.0, 0.0), 0.5 * sin(t + length(uv) * 5.0));
    color = vec4(col, 1.0);
}
