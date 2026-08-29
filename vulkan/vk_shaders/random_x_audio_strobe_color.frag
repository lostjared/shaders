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










vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0/3.0, 1.0/3.0, 3.0);
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
