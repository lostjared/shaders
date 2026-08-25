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
    vec3 tex = texture(samp, tc).rgb;
    float luma = dot(tex, vec3(0.299, 0.587, 0.114));

    // Amplitude sets the sort threshold - louder = more sorted
    float threshold = 1.0 - clamp(amp_smooth * 2.0, 0.0, 0.95);

    // Pixels above threshold get shifted based on bass
    vec2 uv = tc;
    if (luma > threshold) {
        float sortDir = amp_low * 0.05 * sin(time_f * 2.0);
        uv.x += sortDir * (luma - threshold);
        // Mids add vertical sort
        float vSort = amp_mid * 0.03 * cos(time_f * 1.5);
        uv.y += vSort * (luma - threshold);
    }

    uv = clamp(uv, 0.0, 1.0);
    vec3 sorted = texture(samp, uv).rgb;

    // Blend original and sorted based on RMS
    vec3 col = mix(tex, sorted, clamp(amp_rms * 2.0, 0.0, 1.0));

    // Treble adds horizontal banding artifact
    float band = sin(tc.y * iResolution.y * 0.5 + time_f * amp_high * 30.0);
    band = smoothstep(0.95, 1.0, band) * amp_high * 0.15;
    col += band;

    // Peak contrast boost
    float contrast = 1.0 + smoothstep(0.5, 1.0, amp_peak) * 0.5;
    col = (col - 0.5) * contrast + 0.5;

    color = vec4(clamp(col, 0.0, 1.0), 1.0);
}
