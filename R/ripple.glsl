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

float ripple(vec2 pos, float time, float speed, float frequency) {
    float aspectRatio = iResolution.x / iResolution.y;
    pos.x *= aspectRatio;
    float d = distance(pos, vec2(0.5 * aspectRatio, 0.5));
    return sin(d * frequency - time * speed) * exp(-d * 3.0);
}

void main(void) {
    vec2 pos = tc;
    float time_t = mod(time_f, 10.0);
    float audioFreq = 12.0 + amp_mid * 20.0;
    float x = ripple(pos, time_f, 0.5, audioFreq);
    pos *= sin(x * time_t);
    color = texture(samp, pos);

    // --- Audio Reactivity: direct output modulation ---
    float _ab = clamp(amp_peak, 0.0, 1.0);
    float _abass = clamp(amp_low, 0.0, 1.0);
    color.rgb *= 1.0 + _ab * 0.6;
    color.rgb = mix(color.rgb, color.rgb * vec3(1.0 + _abass * 0.3, 1.0 - _abass * 0.15, 1.0 + clamp(amp_high, 0.0, 1.0) * 0.25), _ab);
    // --- End Audio Reactivity ---

}
