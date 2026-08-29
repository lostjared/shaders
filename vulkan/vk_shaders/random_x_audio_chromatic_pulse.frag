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
#define amp_high ext.audio_bands.z
#define amp_low ext.audio_bands.x
#define amp_mid ext.audio_bands.y
#define amp_peak ext.u2.w
#define amp_rms ext.u3.z
#define amp_smooth ext.u3.w
#define iResolution ext.u0.zw
#define iamp ext.u1.z
#define time_f ext.u2.y

layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;










void main(void) {
    vec2 center = vec2(0.5);
    vec2 dir = normalize(tc - center + 0.001);

    // Treble drives chromatic separation distance
    float chromaDist = amp_high * 0.04 + amp_peak * 0.02;

    // Bass wobbles the direction
    float wobble = amp_low * 0.5 * sin(time_f * 3.0 + length(tc - center) * 20.0);
    float c = cos(wobble), s = sin(wobble);
    dir = vec2(c * dir.x - s * dir.y, s * dir.x + c * dir.y);

    float r = texture(samp, clamp(tc + dir * chromaDist, 0.0, 1.0)).r;
    float g = texture(samp, clamp(tc, 0.0, 1.0)).g;
    float b = texture(samp, clamp(tc - dir * chromaDist, 0.0, 1.0)).b;

    vec3 col = vec3(r, g, b);

    // Mids add a pulsing radial offset
    float radPulse = amp_mid * sin(length(tc - center) * 30.0 - time_f * 5.0) * 0.02;
    vec3 col2 = texture(samp, clamp(tc + dir * radPulse, 0.0, 1.0)).rgb;
    col = mix(col, col2, 0.3);

    // Smooth amp global glow
    col *= 1.0 + amp_smooth * 0.3;

    // Peak brightness
    col += smoothstep(0.6, 1.0, amp_peak) * 0.2;

    color = vec4(clamp(col, 0.0, 1.0), 1.0);
}
