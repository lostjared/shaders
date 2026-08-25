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

// Two-strip Technicolor (red/cyan biased).
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float r = c.r;
    float gb = (c.g + c.b) * 0.5;
    vec3 strip = vec3(r * 1.10, gb * 0.95, gb * 1.05);
    strip = (strip - 0.5) * 1.10 + 0.5;
    color = vec4(clamp(strip, 0.0, 1.0), 1.0);
}
