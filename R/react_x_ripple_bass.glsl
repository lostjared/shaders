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
    float aLow  = clamp(amp_low,  0.0, 1.0);
    float aPk   = clamp(amp_peak, 0.0, 1.0);
    float aRms  = clamp(amp_rms,  0.0, 1.0);

    vec2 center = vec2(0.5);
    vec2 uv = tc - center;
    float dist = length(uv);

    float rippleFreq = 10.0 + aLow * 20.0;
    float rippleSpeed = 6.28318 * (1.0 + aRms * 3.0);
    float rippleAmt = 0.05 + aPk * 0.2;
    float ripple = sin(rippleFreq * dist - time_f * rippleSpeed) * rippleAmt;

    uv += uv * ripple;
    uv += center;

    color = texture(samp, uv);
}
