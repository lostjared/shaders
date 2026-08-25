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

// Metal orbital — subtle ring highlight around screen center, slow rotation.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec3 c = texture(samp, tc).rgb;
    vec2 p = tc - 0.5;
    p.x *= iResolution.x / iResolution.y;
    float r = length(p);
    float a = atan(p.y, p.x) + time_f * 0.4;
    float ring = smoothstep(0.05, 0.0, abs(r - 0.32));
    float arc = smoothstep(0.0, 0.5, sin(a * 2.0)) * ring;
    color = vec4(c + vec3(0.85, 0.95, 1.15) * arc * 0.65, 1.0);
}
