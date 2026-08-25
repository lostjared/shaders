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
    vec2 dir = tc - center;

    // Each band splits a different channel in a different direction
    float lowSplit = amp_low * 0.04;
    float midSplit = amp_mid * 0.03;
    float highSplit = amp_high * 0.05;

    // Bass pushes R channel diagonally
    vec2 rOff = dir * lowSplit + vec2(lowSplit * sin(time_f * 2.0), lowSplit * cos(time_f * 1.5));
    // Mids push G channel vertically
    vec2 gOff = vec2(0.0, midSplit * sin(time_f * 3.0 + 1.0));
    // Treble pushes B channel horizontally
    vec2 bOff = vec2(-highSplit * cos(time_f * 4.0), 0.0);

    float r = texture(samp, clamp(tc + rOff, 0.0, 1.0)).r;
    float g = texture(samp, clamp(tc + gOff, 0.0, 1.0)).g;
    float b = texture(samp, clamp(tc + bOff, 0.0, 1.0)).b;

    vec3 col = vec3(r, g, b);

    // RMS adds wave distortion
    float wave = amp_rms * 0.01 * sin(tc.y * 50.0 + time_f * 5.0);
    vec3 col2 = texture(samp, clamp(tc + vec2(wave, 0.0), 0.0, 1.0)).rgb;
    col = mix(col, col2, 0.2);

    // Peak inversion flash
    float inv = smoothstep(0.8, 1.0, amp_peak);
    col = mix(col, 1.0 - col, inv * 0.5);

    // Smooth brightness
    col *= 1.0 + amp_smooth * 0.2;

    color = vec4(clamp(col, 0.0, 1.0), 1.0);
}
