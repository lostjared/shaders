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

// Cool moody color grade for sci-fi / horror games.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec3 c = texture(samp, tc).rgb;
    c = (c - 0.5) * 1.08 + 0.46;
    c *= vec3(0.88, 0.97, 1.08);
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    c = mix(vec3(lum) * vec3(0.9, 1.0, 1.1), c, 0.78);
    color = vec4(clamp(c, 0.0, 1.0), 1.0);
}
