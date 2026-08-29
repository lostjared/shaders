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

// Fractal ocean — soft blue tint with slow undulating wave bands.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec3 c = texture(samp, tc).rgb;
    vec2 p = tc * 4.0;
    float w = sin(p.x + time_f * 0.4) * 0.5 + sin(p.y * 1.3 + time_f * 0.3) * 0.5;
    w = w * 0.5 + 0.5;
    vec3 ocean = mix(vec3(0.05, 0.25, 0.55), vec3(0.35, 0.75, 1.10), w);
    color = vec4(mix(c, c * ocean * 2.2, 0.50), 1.0);
}
