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
    float aspect = iResolution.x / iResolution.y;
    vec2 uv = (tc - 0.5) * vec2(aspect, 1.0);
    float dist = length(uv);

    // Bass spawns outward ripple rings
    float ringSpeed = 4.0 + amp_low * 8.0;
    float ringFreq = 20.0 + amp_low * 30.0;
    float ripple = sin(dist * ringFreq - time_f * ringSpeed) * exp(-dist * 2.0);

    // Mids add angular wobble to the rings
    float angle = atan(uv.y, uv.x);
    ripple += amp_mid * 0.3 * sin(angle * 4.0 + time_f * 2.0) * exp(-dist * 3.0);

    // Apply ripple displacement
    float displacement = ripple * (0.02 + amp_peak * 0.04);
    vec2 rippleUV = tc + normalize(uv + 0.001) * displacement;
    rippleUV = clamp(rippleUV, 0.0, 1.0);

    vec4 tex = texture(samp, rippleUV);

    // Treble adds bright ring outlines
    float ringLine = abs(sin(dist * ringFreq * 0.5 - time_f * ringSpeed * 0.5));
    ringLine = smoothstep(0.95, 1.0, ringLine) * amp_high * 0.5;
    tex.rgb += ringLine * vec3(0.5, 0.8, 1.0);

    // RMS brightness
    tex.rgb *= 1.0 + amp_rms * 0.3;

    // Peak flash
    tex.rgb += smoothstep(0.6, 1.0, amp_peak) * 0.2;

    color = tex;
}
