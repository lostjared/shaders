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

// Metal opal — iridescent rainbow shift on bright pixels (oil-slick look).
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    float h = lum + tc.x * 0.2 + tc.y * 0.15 + time_f * 0.05;
    vec3 opal = 0.5 + 0.5 * cos(6.28318 * (h + vec3(0.0, 0.33, 0.67)));
    float mask = smoothstep(0.30, 0.85, lum);
    color = vec4(mix(c, c * (0.5 + 1.1 * opal), mask * 0.75), 1.0);
}
