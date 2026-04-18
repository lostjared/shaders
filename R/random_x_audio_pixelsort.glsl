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
