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

// Shadow realm: dark desaturated phase with violet highlights.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec2 p = tc - 0.5;
    float wave = sin((p.x * p.y) * 120.0 + time_f * 2.0) * 0.008;
    vec3 c = texture(samp, clamp(tc + vec2(wave, -wave), 0.0, 1.0)).rgb;
    float lum = dot(c, vec3(0.299, 0.587, 0.114));
    float pulse = 0.5 + 0.5 * sin(time_f * 1.5);
    c = mix(c, vec3(lum) * vec3(0.55, 0.45, 0.8), 0.75);
    c *= 0.55 + 0.25 * pulse;
    c += vec3(0.18, 0.0, 0.35) * smoothstep(0.05, 0.35, dot(p, p));
    color = vec4(c, 1.0);
}
