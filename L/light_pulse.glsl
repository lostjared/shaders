#version 330

in vec2 tc;
out vec4 color;
uniform sampler2D samp;
uniform float time_f;
uniform float amp_peak;
uniform float amp_rms;
uniform float amp_smooth;
uniform float amp_low;
uniform float amp_mid;
uniform float amp_high;
uniform float iamp;

void main(void) {
    float lightCycleSpeed = 2.0;
    float lightIntensity = 0.5 + (0.5 + amp_rms * 0.5) * sin(time_f * lightCycleSpeed);
    vec3 rainbow = vec3(
        sin(time_f + 0.0) * 0.5 + 0.5,
        sin(time_f + 2.094) * 0.5 + 0.5,
        sin(time_f + 4.188) * 0.5 + 0.5
    );

    vec4 rainbowLight = vec4(rainbow, 1.0) * lightIntensity;

    vec4 originalColor = texture(samp, tc);

    color = mix(originalColor, rainbowLight, 0.5 * lightIntensity);

    // --- Audio Reactivity: direct output modulation ---
    float _ab = clamp(amp_peak, 0.0, 1.0);
    float _abass = clamp(amp_low, 0.0, 1.0);
    color.rgb *= 1.0 + _ab * 0.6;
    color.rgb = mix(color.rgb, color.rgb * vec3(1.0 + _abass * 0.3, 1.0 - _abass * 0.15, 1.0 + clamp(amp_high, 0.0, 1.0) * 0.25), _ab);
    // --- End Audio Reactivity ---

}

