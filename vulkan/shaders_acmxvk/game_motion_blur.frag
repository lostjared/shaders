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

// Very soft motion-blur fake using mild horizontal blur (preserves picture).
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec2 px = 1.0 / iResolution;
    vec3 acc = vec3(0.0);
    float total = 0.0;
    for (int i = -3; i <= 3; ++i) {
        float w = exp(-float(i*i) * 0.3);
        acc += texture(samp, tc + vec2(float(i) * px.x * 1.2, 0.0)).rgb * w;
        total += w;
    }
    color = vec4(acc / total, 1.0);
}
