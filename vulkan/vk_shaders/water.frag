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
#define time_f ext.u2.y

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;


void main(void) {
    float speed = 5.0;
    float amplitude = 0.03;
    float wavelength = 10.0;
    float ripple = sin(tc.x * wavelength + time_f * speed) * amplitude;
    ripple += sin(tc.y * wavelength + time_f * speed) * amplitude;
    vec2 rippleTC = tc + vec2(ripple, ripple);
    vec4 originalColor = texture(samp, tc);
    vec4 rippleColor = texture(samp, rippleTC);
    color = mix(originalColor, rippleColor, 0.5);
}
