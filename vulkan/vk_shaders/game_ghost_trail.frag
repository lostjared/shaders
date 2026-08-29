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

// Ghost afterimage: fake echo trail by sampling several time-shifted offsets.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec3 acc = vec3(0.0);
    float total = 0.0;
    for (int i = 0; i < 5; ++i) {
        float t = float(i) / 4.0;
        vec2 off = vec2(sin(time_f + t * 3.0), cos(time_f * 0.8 + t * 3.0)) * 0.012 * t;
        vec3 s = texture(samp, tc + off).rgb;
        float w = 1.0 - t * 0.85;
        acc += s * w * (1.0 - 0.2 * t * vec3(0.0, 0.6, 1.2));
        total += w;
    }
    vec3 c = acc / total;
    color = vec4(c * vec3(0.9, 1.0, 1.1), 1.0);
}
