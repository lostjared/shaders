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
    vec2 normCoord = (tc * 2.0) - vec2(1.0, 1.0);
    normCoord.x *= iResolution.x / iResolution.y;
    float dist = length(normCoord);

    float stretchMagnitude = (0.5 + amp_low * 0.5) + sin(time_f) * 0.50;
    float stretchFactor = 1.0 + pow(dist, 2.0) * stretchMagnitude;
    vec2 stretchedCoord = normCoord / stretchFactor;
    stretchedCoord.x *= iResolution.y / iResolution.x;
    stretchedCoord = (stretchedCoord + vec2(1.0, 1.0)) / 2.0;

    stretchedCoord = clamp(stretchedCoord, 0.0, 1.0);
    color = texture(samp, stretchedCoord);

    // --- Audio Reactivity: direct output modulation ---
    float _ab = clamp(amp_peak, 0.0, 1.0);
    float _abass = clamp(amp_low, 0.0, 1.0);
    color.rgb *= 1.0 + _ab * 0.6;
    color.rgb = mix(color.rgb, color.rgb * vec3(1.0 + _abass * 0.3, 1.0 - _abass * 0.15, 1.0 + clamp(amp_high, 0.0, 1.0) * 0.25), _ab);
    // --- End Audio Reactivity ---

}
