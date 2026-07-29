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
    float aMid  = clamp(amp_mid,  0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float aPk   = clamp(amp_peak, 0.0, 1.0);

    vec4 baseColor = texture(samp, tc);
    float hashSeed = fract(sin(dot(tc, vec2(12.9898, 78.233))) * 43758.5453);
    float glitchAmt = 0.02 + aPk * 0.15;
    float glitchOffsetX = hashSeed * glitchAmt * sin(time_f * (15.0 + aHigh * 15.0));
    float glitchOffsetY = fract(cos(dot(tc, vec2(4.898, 7.23))) * 23421.6312) * glitchAmt * cos(time_f * (15.0 + aLow * 15.0));
    vec2 glitchTc = tc + vec2(glitchOffsetX, glitchOffsetY);
    vec4 glitchColor = texture(samp, glitchTc);
    float glitchStrength = 0.2 + 0.6 * aMid + 0.2 * aPk;
    color = mix(baseColor, glitchColor, glitchStrength);
}
