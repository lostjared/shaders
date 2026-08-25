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

// HDR-style contrast and saturation lift. Makes dull SDR games pop.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec3 c = texture(samp, tc).rgb;
    vec3 mapped = c / (c + vec3(0.18));
    mapped = mapped * 1.18;
    float lum = dot(mapped, vec3(0.299, 0.587, 0.114));
    mapped = mix(vec3(lum), mapped, 1.20);
    mapped = pow(clamp(mapped, 0.0, 1.0), vec3(0.93));
    color = vec4(mapped, 1.0);
}
