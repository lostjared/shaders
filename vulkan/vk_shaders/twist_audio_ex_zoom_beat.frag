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

layout(set = 0, binding = 3) uniform sampler1D spectrum;

// Bass beats both twist and zoom toward the center.
void main(void) {
    float bass = texture(spectrum, 0.04).r;
    float zoom = 1.0 - bass * 0.4;

    vec2 center = vec2(0.5);
    vec2 d = (tc - center) * zoom;
    float radius = length(d);

    float twistStrength = 1.0 + bass * 5.0;
    float angle = twistStrength * (radius - 1.0) + time_f;
    float c = cos(angle), s = sin(angle);
    vec2 twistedTC = mat2(c, -s, s, c) * d + center;

    float ripple = sin(tc.x * 10.0 + time_f * 5.0) * (0.02 + bass * 0.04);
    ripple += sin(tc.y * 10.0 + time_f * 5.0) * (0.02 + bass * 0.04);
    vec2 rippleTC = tc + vec2(ripple);

    color = texture(samp, mix(rippleTC, twistedTC, 0.5));
}
