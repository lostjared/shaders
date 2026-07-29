#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_rms;
uniform float amp_smooth;
uniform float amp_low;
uniform float amp_mid;
uniform float amp_high;
uniform float iamp;

void main(void) {
    vec2 uv = tc - vec2(0.5);
    float radius = length(uv) * 2.0;

    float frequency = 10.0;
    float amplitude = 0.1;

    float audioAmp = amplitude + amp_low * 0.3;
float pulsate = audioAmp * sin(time_f * frequency);
float adjustedRadius = clamp(radius + pulsate, 0.0, 1.0);

    vec3 neonBlue = vec3(0.0, 1.0, 1.0);
    vec3 neonPink = vec3(1.0, 0.0, 0.5);
    vec3 gradientColor = mix(neonBlue, neonPink, adjustedRadius);\
    vec4 texColor = texture(samp, tc);
    vec3 finalColor = texColor.rgb * gradientColor;

    // --- Audio Reactivity: direct output modulation ---
    float _ab = clamp(amp_peak, 0.0, 1.0);
    float _abass = clamp(amp_low, 0.0, 1.0);
    finalColor *= 1.0 + _ab * 0.6;
    finalColor = mix(finalColor, finalColor * vec3(1.0 + _abass * 0.3, 1.0 - _abass * 0.15, 1.0 + clamp(amp_high, 0.0, 1.0) * 0.25), _ab);
    // --- End Audio Reactivity ---

    color = vec4(finalColor, texColor.a);
}
