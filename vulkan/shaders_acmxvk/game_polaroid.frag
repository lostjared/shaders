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

// Polaroid look - lifted blacks, faded highlights, warm cast.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec3 c = texture(samp, tc).rgb;
    c = c * 0.85 + 0.10;
    c *= vec3(1.06, 1.00, 0.92);
    c = mix(c, vec3(dot(c, vec3(0.3, 0.6, 0.1))), 0.10);
    vec2 v = tc - 0.5;
    c *= mix(0.85, 1.0, smoothstep(0.5, 0.0, dot(v, v)));
    color = vec4(clamp(c, 0.0, 1.0), 1.0);
}
