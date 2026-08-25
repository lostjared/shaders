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



float pingPong(float value, float range) {
    float modValue = mod(value, 2.0 * range);
    return range - abs(modValue - range);
}


void main() {
    vec2 uv = tc;
    vec4 pixelColor = texture(samp, uv);
    float scale = 0.5 + 0.5 * pingPong(time_f, 8.0) + 1.5;
    vec4 scaledColor = mod(pixelColor * scale, 1.0);
    color = scaledColor;
    color.a = 1.0;
}
