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



float pingPong(float x, float length) {
    float modVal = mod(x, length * 2.0);
    return modVal <= length ? modVal : length * 2.0 - modVal;
}

void main(void) {
    vec2 uv = tc;
    float boil = sin(uv.y * 20.0 + time_f * 6.0) * 0.2 * time_f;
    boil += cos(uv.x * 30.0 + time_f * 4.0) * 0.2 * time_f;
    boil += sin((uv.x + uv.y) * 25.0 + time_f * 5.0) * 0.1 * time_f;
    uv.y += boil;
    uv.x += boil;
    float time_t = pingPong(time_f, 10.0);
    vec4 distorted = texture(samp, sin(uv * time_t));
    vec4 baseTexture = texture(samp, tc);
    color = mix(baseTexture, distorted, 0.5);
}
