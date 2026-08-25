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

// Two independent shears per axis driven by two distinct frequency bands.
void main(void) {
    float lo = texture(spectrum, 0.08).r;
    float hi = texture(spectrum, 0.55).r;

    vec2 center = vec2(0.5);
    vec2 d = tc - center;
    float radius = length(d);

    float ripple = sin(tc.x * (8.0 + lo * 12.0) + time_f * 5.0) * (0.02 + hi * 0.05);
    ripple += sin(tc.y * (8.0 + hi * 12.0) + time_f * 5.0) * (0.02 + lo * 0.05);
    vec2 rippleTC = tc + vec2(ripple);

    float angleX = lo * 4.0 * (radius - 1.0) + time_f;
    float angleY = hi * 4.0 * (radius - 1.0) - time_f * 0.7;
    vec2 t = d;
    t.x = cos(angleX) * d.x - sin(angleX) * d.y;
    t.y = sin(angleY) * d.x + cos(angleY) * d.y;
    vec2 twistedTC = t + center;

    color = texture(samp, mix(rippleTC, twistedTC, 0.5));
}
