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
    float foldAmount = sin(time_f * 3.14159);
    
    if (foldAmount > 0.0) {
        if (uv.x < 0.5) {
            uv.x = mix(uv.x, 0.5, foldAmount);
        } else {
            uv.x = mix(uv.x, 0.5, foldAmount);
        }
    } else {
        uv.x = mix(0.5 + abs(uv.x - 0.5), uv.x, abs(foldAmount));
    }
    vec2 translate = vec2(sin(time_f * 2.0), cos(time_f * 2.0)) * 0.25;
    uv += translate * foldAmount;
    uv = (uv - 0.5) * 1.5 + 0.5;
    uv = clamp(uv, 0.0, 1.0);
    color = texture(samp, uv);
}
