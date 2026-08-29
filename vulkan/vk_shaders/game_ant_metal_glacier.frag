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

// Metal glacier — icy blue tint with subtle frost speckle.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }

void main(void) {
    vec3 c = texture(samp, tc).rgb;
    vec3 glacier = c * vec3(0.78, 0.95, 1.20) + vec3(0.04, 0.08, 0.16);
    float n = hash(floor(tc * iResolution / 2.0));
    float frost = step(0.94, n) * 0.50;
    color = vec4(glacier + vec3(0.8, 0.95, 1.0) * frost, 1.0);
}
