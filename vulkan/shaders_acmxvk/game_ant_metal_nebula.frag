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

// Metal nebula — cloudy color washes drift across, very subtle.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float n = sin(tc.x * 3.0 + time_f * 0.2) * 0.5 + sin(tc.y * 4.0 - time_f * 0.15) * 0.5;
    n = n * 0.5 + 0.5;
    vec3 neb = mix(vec3(0.65, 0.20, 0.95), vec3(0.20, 0.55, 1.10), n);
    color = vec4(c + neb * 0.40, 1.0);
}
