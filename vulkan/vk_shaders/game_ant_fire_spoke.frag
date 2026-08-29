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

// Fire spoke — slow radial warm glow from screen center.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec3 c = texture(samp, tc).rgb;
    vec2 p = tc - 0.5;
    float a = atan(p.y, p.x);
    float r = length(p);
    float spokes = 0.5 + 0.5 * sin(a * 8.0 + time_f * 0.4);
    float glow = smoothstep(0.7, 0.0, r) * spokes;
    vec3 fire = vec3(1.0, 0.55, 0.20) * glow * 0.55;
    color = vec4(c + fire, 1.0);
}
