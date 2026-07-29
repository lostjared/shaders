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
float noise(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

void main(void) {
    vec2 uv = tc;
    float time = time_f * 0.1;
    vec2 noiseOffset = vec2(noise(uv + time), noise(uv - time));
    float distortAmount = 0.2 + amp_low * 0.4;
    noiseOffset = (noiseOffset - 0.5) * distortAmount;
    vec2 nuv = uv + noiseOffset;
    vec4 texColor = texture(samp, nuv);
    vec4 smokeColor = mix(texColor, vec4(0.6, 0.6, 0.6, 1.0), 0.2);

    // --- Audio Reactivity: direct output modulation ---
    float _ab = clamp(amp_peak, 0.0, 1.0);
    float _abass = clamp(amp_low, 0.0, 1.0);
    smokeColor.rgb *= 1.0 + _ab * 0.6;
    smokeColor.rgb = mix(smokeColor.rgb, smokeColor.rgb * vec3(1.0 + _abass * 0.3, 1.0 - _abass * 0.15, 1.0 + clamp(amp_high, 0.0, 1.0) * 0.25), _ab);
    // --- End Audio Reactivity ---

    color = smokeColor;
}
