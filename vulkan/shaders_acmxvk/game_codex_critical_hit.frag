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

// Critical hit: white flash, red shards, and impact ripple.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec2 p = tc - 0.5;
    float r = length(p);
    float beat = pow(0.5 + 0.5 * sin(time_f * 10.0), 8.0);
    float shards = step(0.92, sin(atan(p.y, p.x) * 18.0 + r * 25.0 - time_f * 8.0) * 0.5 + 0.5);
    float ripple = exp(-pow((r - 0.22 - beat * 0.25) * 18.0, 2.0));
    vec3 c = texture(samp, clamp(tc - normalize(p + 1e-5) * ripple * 0.03, 0.0, 1.0)).rgb;
    c = mix(c, vec3(1.0), beat * 0.35);
    c += vec3(1.0, 0.05, 0.02) * shards * ripple * 0.9;
    color = vec4(c, 1.0);
}
