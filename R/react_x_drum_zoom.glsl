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
    float aLow = clamp(amp_low, 0.0, 1.0);
    float aPk = clamp(amp_peak, 0.0, 1.0);
    float aRms = clamp(amp_rms, 0.0, 1.0);

    vec2 uv = tc - 0.5;
    float drumEffect = aPk * 0.25 + aLow * 0.15;
    float pulse = 1.0 + drumEffect * sin(time_f * (8.0 + aRms * 12.0));
    vec2 drumUV = uv * pulse;
    color = texture(samp, drumUV + 0.5);
}
