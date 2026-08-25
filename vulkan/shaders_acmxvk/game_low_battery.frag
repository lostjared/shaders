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

// Low-battery handheld: dim, slight green-yellow shift, occasional flicker.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



float hash(float n) { return fract(sin(n) * 43758.5453); }

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float t = floor(time_f * 12.0);
    float flicker = 0.85 + 0.15 * hash(t);
    if (hash(t * 0.3) > 0.96) flicker *= 0.4;
    c *= flicker;
    c *= vec3(0.95, 1.0, 0.78);
    float vig = smoothstep(1.0, 0.5, length(tc - 0.5));
    color = vec4(c * vig * 0.85, 1.0);
}
