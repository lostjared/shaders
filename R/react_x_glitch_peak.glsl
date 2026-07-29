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
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float aPk   = clamp(amp_peak, 0.0, 1.0);
    float aRms  = clamp(amp_rms,  0.0, 1.0);

    vec4 baseColor = texture(samp, tc);
    float glitchAmt = 0.02 + aPk * 0.12;
    float glitchSpeed = 10.0 + aRms * 30.0;
    float glitchOffsetX = sin(time_f * glitchSpeed + tc.y * (20.0 + aLow * 20.0)) * glitchAmt;
    float glitchOffsetY = cos(time_f * (glitchSpeed * 1.5) + tc.x * (25.0 + aHigh * 15.0)) * glitchAmt;
    vec2 glitchTc = tc + vec2(glitchOffsetX, glitchOffsetY);
    vec4 glitchColor = texture(samp, glitchTc);
    float glitchStrength = 0.3 + 0.7 * aPk;
    color = mix(baseColor, glitchColor, glitchStrength);
}
