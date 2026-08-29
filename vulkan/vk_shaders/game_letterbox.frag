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

// 2.39:1 cinema letterbox with mild warm grade for cutscenes.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    float aspect = iResolution.x / iResolution.y;
    float bar = (1.0 - (aspect / 2.39)) * 0.5;
    if (tc.y < bar || tc.y > 1.0 - bar) {
        color = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }
    vec3 c = texture(samp, tc).rgb;
    c = (c - 0.5) * 1.1 + 0.5;
    c *= vec3(1.06, 1.00, 0.93);
    color = vec4(clamp(c, 0.0, 1.0), 1.0);
}
