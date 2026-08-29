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

// Lava damage: molten heat shimmer and orange overexposure.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec2 p = tc - 0.5;
    float heat = sin(tc.y * 80.0 + time_f * 9.0) * 0.006;
    heat += sin(tc.x * 35.0 - time_f * 4.0) * 0.004;
    vec3 c = texture(samp, clamp(tc + vec2(heat, heat * 0.4), 0.0, 1.0)).rgb;
    float edge = smoothstep(0.08, 0.35, dot(p, p));
    float pulse = 0.55 + 0.45 * sin(time_f * 3.0);
    vec3 lava = vec3(1.0, 0.32, 0.02);
    c = mix(c, lava + c * 0.35, edge * pulse * 0.55);
    color = vec4(c, 1.0);
}
