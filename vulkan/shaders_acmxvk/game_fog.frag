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

// Soft fog overlay - distance-y based mist using vertical gradient.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float fogAmt = smoothstep(0.2, 0.85, 1.0 - tc.y) * 0.35;
    vec3 fog = vec3(0.78, 0.82, 0.88);
    c = mix(c, fog, fogAmt);
    vec2 v = tc - 0.5;
    c *= mix(0.85, 1.0, smoothstep(0.6, 0.05, dot(v, v)));
    color = vec4(c, 1.0);
}
