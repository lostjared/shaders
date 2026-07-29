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
    vec2 centeredCoord = (tc * 2.0 - 1.0) * vec2(iResolution.x / iResolution.y, 1.0);
    float angle = atan(centeredCoord.y, centeredCoord.x) + time_f;
    float radius = length(centeredCoord);
    float spiral = sin((10.0 + amp_mid * 15.0) * angle - 3.0 * time_f) * exp(-3.0 * radius);
    vec3 lightColor = vec3(0.1, 0.5, 0.8) * 0.5 * (1.0 + spiral);
    lightColor = sin(lightColor * time_f);
    vec4 texColor = texture(samp, tc);
    color = vec4(texColor.rgb * lightColor, texColor.a);

    // --- Audio Reactivity: direct output modulation ---
    float _ab = clamp(amp_peak, 0.0, 1.0);
    float _abass = clamp(amp_low, 0.0, 1.0);
    color.rgb *= 1.0 + _ab * 0.6;
    color.rgb = mix(color.rgb, color.rgb * vec3(1.0 + _abass * 0.3, 1.0 - _abass * 0.15, 1.0 + clamp(amp_high, 0.0, 1.0) * 0.25), _ab);
    // --- End Audio Reactivity ---

}
