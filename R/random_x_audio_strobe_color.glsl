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

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void main(void) {
    vec3 tex = texture(samp, tc).rgb;

    // Peak triggers color strobe
    float peakTrigger = smoothstep(0.4, 0.8, amp_peak);

    // Strobe hue cycles rapidly with time, freezes between beats
    float strobeHue = fract(time_f * 3.0 + amp_mid * 2.0);
    vec3 strobeColor = hsv2rgb(vec3(strobeHue, 0.9, 1.0));

    // Blend strobe color on peaks
    tex = mix(tex, tex * strobeColor * 2.0, peakTrigger * 0.6);

    // Bass dims between beats for contrast
    float dim = 1.0 - amp_low * 0.15 * (1.0 - peakTrigger);
    tex *= dim;

    // Treble adds high-frequency flicker
    float flicker = 1.0 + amp_high * 0.3 * sin(time_f * 60.0);
    tex *= flicker;

    // RMS overall brightness
    tex *= 1.0 + amp_rms * 0.3;

    // Smooth sustain glow
    vec3 glow = hsv2rgb(vec3(fract(strobeHue + 0.33), 0.5, amp_smooth * 0.3));
    tex += glow;

    color = vec4(clamp(tex, 0.0, 1.0), 1.0);
}
