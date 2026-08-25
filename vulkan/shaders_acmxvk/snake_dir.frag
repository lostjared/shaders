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
#define alpha ext.u0.x
#define iResolution ext.u0.zw
#define time_f ext.u2.y

layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;




vec4 snake1() {
    vec2 uv = tc * iResolution;
    float wave = sin(uv.x * 0.05 + time_f * 2.0) * 0.05;
    vec2 shiftedUV = vec2(uv.x, uv.y + wave * iResolution.y);
    vec4 texColor = texture(samp, shiftedUV / iResolution);
    return texColor;
}

vec4 snake2() {
    vec2 uv = tc * iResolution;
    float wave = sin(uv.y * 0.05 + time_f * 2.0) * 0.05;
    vec2 shiftedUV = vec2(uv.x + wave * iResolution.x, uv.y);
    vec4 texColor = texture(samp, shiftedUV / iResolution);
    return texColor;
}

void main(void) {
    float time_t = mod(time_f, 10);
    color = sin(mix(snake1(), snake2(), 0.5) * (alpha * time_t));
    color.a = 1.0;
}
