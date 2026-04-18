#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform vec2 iResolution;
uniform float time_f;
uniform float amp_peak;
uniform float amp_rms;
uniform float amp_smooth;
uniform float amp_low;
uniform float amp_mid;
uniform float amp_high;
uniform float iamp;

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
