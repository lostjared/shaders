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

// Rage meter: fiery edge buildup and center heat punch.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec2 p = tc - 0.5;
    float r2 = dot(p, p);
    float edge = smoothstep(0.08, 0.33, r2);
    float flame = sin(atan(p.y, p.x) * 14.0 + time_f * 7.0 + length(p) * 20.0) * 0.5 + 0.5;
    vec2 uv = tc + normalize(p + 1e-5) * edge * flame * 0.018;
    vec3 c = texture(samp, clamp(uv, 0.0, 1.0)).rgb;
    vec3 fire = mix(vec3(0.8, 0.0, 0.0), vec3(1.0, 0.75, 0.05), flame);
    c = mix(c, fire, edge * (0.25 + 0.35 * sin(time_f * 4.0) * 0.5 + 0.35));
    color = vec4(c, 1.0);
}
