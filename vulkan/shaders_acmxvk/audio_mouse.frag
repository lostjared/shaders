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
#define amp ext.u1.y
#define iMouse ext.mouse
#define iResolution ext.u0.zw
#define time_f ext.u2.y
#define uamp ext.u1.y

layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;






void main(void) {
    vec2 mousePos = iMouse.xy / iResolution.xy; 
    float dist = distance(tc, mousePos);
    float glitchStrength = exp(-dist * 10.0) * (uamp) * 4.0;
    vec2 glitchOffset = vec2(
        sin(time_f * 10.0 + tc.y * 20.0) * glitchStrength,
        cos(time_f * 15.0 + tc.x * 25.0) * glitchStrength
    );

    vec2 distortedTc = tc + glitchOffset;
    color = texture(samp, distortedTc);
    vec4 originalColor = texture(samp, tc);
    float blendFactor = smoothstep(0.0, 0.1, glitchStrength);
    color = mix(originalColor, color, blendFactor);
}
