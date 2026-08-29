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

// Hot desert/lava grade with shimmering heat at the bottom of the frame.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec2 uv = tc;
    float heat = (1.0 - tc.y) * 0.012;
    uv.x += sin(uv.y * 28.0 + time_f * 2.0) * heat;
    vec3 c = texture(samp, uv).rgb;
    c *= vec3(1.10, 0.96, 0.78);
    c = (c - 0.5) * 1.06 + 0.5;
    color = vec4(clamp(c, 0.0, 1.0), 1.0);
}
