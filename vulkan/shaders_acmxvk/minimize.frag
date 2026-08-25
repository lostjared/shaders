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



float ripple(vec2 pos, float time, float speed, float frequency) {
    float aspectRatio = iResolution.x / iResolution.y;
    pos.x *= aspectRatio;
    float d = distance(pos, vec2(0.5 * aspectRatio, 0.5));
    return sin(d * frequency - time * speed) * exp(-d * 3.0);
}

void main(void) {
    vec2 pos = tc;
    float time_t = mod(time_f, 3.5);
    float x = ripple(pos, time_f, 0.5, 12.0);
    pos = (pos * x) + (pos * time_t);
    color = texture(samp, pos);
}

