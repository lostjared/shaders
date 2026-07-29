#version 330 core
in vec2 tc;
out vec4 color;
uniform float time_f;
uniform sampler2D samp;
uniform vec2 iResolution;
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

    vec2 normPos = gl_FragCoord.xy / iResolution.xy;
    float cycle = sin(time_f * (0.3 + aLow * 0.5));
    float movingPhase = normPos.x + cycle;

    float phaseFreq = 10.0 + aMid * 10.0;
    float phaseSpeed = 2.0 + aHigh * 4.0;
    float phase = sin(movingPhase * phaseFreq - time_f * phaseSpeed);
    float phaseAmt = 0.2 + aPk * 0.2;
    vec2 tcAdjusted = tc + vec2(phase, 0.0) * phaseAmt;

    float glitchAmt = 0.02 + aPk * 0.12;
    float glitchFactor = sin(time_f * (5.0 + aHigh * 10.0));
    vec2 glitchOffset = vec2(glitchFactor * glitchAmt);
    vec4 glitchColor = texture(samp, tc + glitchOffset);

    vec4 baseColor = texture(samp, tcAdjusted);
    float mixAmt = 0.3 + aMid * 0.4;
    color = mix(baseColor, glitchColor, mixAmt);
}
