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

// Liquid mirror — soft horizontal sheen band scrolls down the frame.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float band = fract(tc.y - time_f * 0.08);
    float sheen = smoothstep(0.42, 0.50, band) * smoothstep(0.58, 0.50, band);
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    vec3 mir = mix(c, c * 0.85 + vec3(lum) * 0.45, 0.55);
    color = vec4(mir + sheen * vec3(0.85, 0.92, 1.0) * 0.85, 1.0);
}
