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

// Target lock: animated reticle, range rings, and subtle contrast lift.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec2 p = tc - 0.5;
    p.x *= iResolution.x / max(iResolution.y, 1.0);
    float r = length(p);
    float a = atan(p.y, p.x);
    float ring = smoothstep(0.006, 0.0, abs(r - 0.23)) + smoothstep(0.006, 0.0, abs(r - 0.37));
    float ticks = step(0.96, sin(a * 32.0 + time_f * 2.0) * 0.5 + 0.5) * smoothstep(0.42, 0.18, r);
    float cross = smoothstep(0.004, 0.0, abs(p.x)) * smoothstep(0.42, 0.08, abs(p.y));
    cross += smoothstep(0.004, 0.0, abs(p.y)) * smoothstep(0.42, 0.08, abs(p.x));
    vec3 c = texture(samp, tc).rgb;
    c = (c - 0.5) * 1.08 + 0.5 + vec3(1.0, 0.12, 0.05) * min(1.0, ring + ticks + cross) * 0.8;
    color = vec4(c, 1.0);
}
