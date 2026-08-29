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
    vec4 color_solid = vec4(0.3, 0.1, 0.8, 1.0);
    float time_t = pingPong(time_f, 10.0) + 2.0;
    vec4 ctx = texture(samp, tc);
    color = vec4(sin(ctx.rgb * time_t) , ctx.a);
    color = mix(color, color_solid, 0.5);
}
