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

// 6-fold kaleidoscope combat overlay (slowly rotating).
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec2 v = tc - 0.5;
    float a = atan(v.y, v.x);
    float r = length(v);
    float seg = 3.14159 / 3.0;
    a = mod(a + time_f * 0.15, seg);
    a = abs(a - seg * 0.5);
    vec2 uv = vec2(cos(a), sin(a)) * r + 0.5;
    vec3 c = texture(samp, uv).rgb;
    color = vec4(c, 1.0);
}
