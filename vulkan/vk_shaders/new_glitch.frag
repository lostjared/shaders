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
#define value_alpha_b ext.custom_uniforms[1].w
#define value_alpha_g ext.custom_uniforms[1].z
#define value_alpha_r ext.custom_uniforms[1].y

layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;




float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

void main(void) {
    vec2 pos = tc;
    
    vec2 randomOffset = vec2(rand(pos + time_f), rand(pos - time_f));
    
    pos.x += (value_alpha_r * randomOffset.x - 0.5) * 0.05;
    pos.y += (value_alpha_g * randomOffset.y - 0.5) * 0.05;
    
    vec4 texColor = texture(samp, pos);
    vec4 shiftedColor1 = texture(samp, pos + vec2(value_alpha_b * 0.01, 0.0));
    vec4 shiftedColor2 = texture(samp, pos + vec2(0.0, value_alpha_b * 0.01));
    
    color = mix(texColor, (shiftedColor1 + shiftedColor2) * 0.5, 0.5);
}