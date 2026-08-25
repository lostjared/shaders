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
    vec4 baseColor = texture(samp, tc);
    float glitchOffsetX = sin(time_f * 10.0 + tc.y * 20.0) * 0.05;
    float glitchOffsetY = cos(time_f * 15.0 + tc.x * 25.0) * 0.05;
    vec2 glitchTc = tc + vec2(glitchOffsetX, glitchOffsetY);
    vec4 glitchColor = texture(samp, glitchTc);
    float glitchStrength = 0.5 + 0.5 * sin(time_f * 3.0);
    color = mix(baseColor, glitchColor, glitchStrength);
}
