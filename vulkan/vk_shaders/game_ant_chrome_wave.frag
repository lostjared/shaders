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

// Subtle chrome wave sheen — gentle bright band sweeps across screen.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec3 c = texture(samp, tc).rgb;
    vec2 p = tc - 0.5;
    float band = sin(p.x * 4.0 + p.y * 2.0 + time_f * 0.6);
    float sheen = smoothstep(0.65, 1.0, band) * 0.55;
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    vec3 chrome = mix(c, vec3(lum) * vec3(0.90, 0.97, 1.12), 0.45);
    chrome += sheen * vec3(0.9, 0.95, 1.0);
    color = vec4(chrome, 1.0);
}
