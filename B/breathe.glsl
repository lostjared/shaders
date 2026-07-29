#version 330 core
out vec4 color;

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
     vec2 normCoord = gl_FragCoord.xy / iResolution.xy;
   vec2 centeredCoord = normCoord - vec2(0.5, 0.5);
    centeredCoord.x *= iResolution.x / iResolution.y;
    float audioScale = 0.1 + amp_low * 0.4;
    float scale = 1.0 + audioScale * sin(time_f * 2.0);
    vec2 scaledCoord = centeredCoord * scale;
    scaledCoord.x *= iResolution.y / iResolution.x;
    scaledCoord += vec2(0.5, 0.5);
    scaledCoord = clamp(scaledCoord, 0.0, 1.0);
    color = texture(samp, scaledCoord);

    // --- Audio Reactivity: direct output modulation ---
    float _ab = clamp(amp_peak, 0.0, 1.0);
    float _abass = clamp(amp_low, 0.0, 1.0);
    color.rgb *= 1.0 + _ab * 0.6;
    color.rgb = mix(color.rgb, color.rgb * vec3(1.0 + _abass * 0.3, 1.0 - _abass * 0.15, 1.0 + clamp(amp_high, 0.0, 1.0) * 0.25), _ab);
    // --- End Audio Reactivity ---

}
