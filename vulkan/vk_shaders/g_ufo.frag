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



vec2 rotate(vec2 pos, float angle) {
    float s = sin(angle);
    float c = cos(angle);
    pos -= vec2(0.5);
    pos = mat2(c, -s, s, c) * pos;
    pos += vec2(0.5);
    return pos;
}

void main(void) {
    vec2 pos = tc;
    float aspectRatio = iResolution.x / iResolution.y;
    pos.x *= aspectRatio;

    float spinSpeed = time_f * 0.5;
    pos = rotate(pos, spinSpeed);
    float dist = distance(pos, vec2(0.5 * aspectRatio, 0.5));
    float scale = 1.0 + 0.2 * sin(dist * 15.0 - time_f * 2.0);
    pos = (pos - vec2(0.5)) * scale + vec2(0.5);
    color = texture(samp, pos);
}

