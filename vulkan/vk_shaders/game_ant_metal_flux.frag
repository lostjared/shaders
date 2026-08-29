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

// Metal flux — flowing horizontal flux lines, very low contrast.
layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;



void main(void) {
    vec3 c = texture(samp, tc).rgb;
    float flux = sin(tc.y * 80.0 + sin(tc.x * 4.0 + time_f * 0.6) * 2.0);
    flux = smoothstep(0.6, 1.0, flux) * 0.32;
    color = vec4(c + vec3(0.5, 0.85, 1.10) * flux, 1.0);
}
