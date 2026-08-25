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

// Slow red pulse on the edges - "low health" feedback.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec3 c = texture(samp, tc).rgb;
    vec2 v = tc - 0.5;
    float r = dot(v, v);
    float pulse = 0.5 + 0.5 * sin(time_f * 2.4);
    float edge = smoothstep(0.10, 0.32, r);
    vec3 red = vec3(0.85, 0.05, 0.05);
    c = mix(c, mix(c * 0.7, red, 0.55), edge * pulse);
    color = vec4(c, 1.0);
}
