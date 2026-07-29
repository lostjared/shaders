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
    float aLow  = clamp(amp_low,  0.0, 1.0);
    float aMid  = clamp(amp_mid,  0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float aPk   = clamp(amp_peak, 0.0, 1.0);
    float aRms  = clamp(amp_rms,  0.0, 1.0);

    vec2 normPos = (gl_FragCoord.xy / iResolution.xy) * 2.0 - 1.0;
    float dist = length(normPos);

    float phaseFreq = 10.0 + aLow * 10.0;
    float phaseSpeed = 4.0 + aRms * 4.0;
    float phase = sin(dist * phaseFreq - time_f * phaseSpeed);
    float phaseAmt = 0.2 + aPk * 0.3;
    vec2 tcAdjusted = tc + (normPos * phaseAmt * phase);

    vec2 centeredCoord = tc * 2.0 - 1.0;
    float stretchFactor = 1.0 + (1.0 - abs(centeredCoord.y)) * (0.3 + aMid * 0.5);
    centeredCoord.x *= sin(stretchFactor * time_f);
    vec2 stretchedCoord = (centeredCoord + 1.0) / 2.0;
    vec4 color2 = texture(samp, stretchedCoord);

    vec4 color1 = texture(samp, tcAdjusted);

    float glitchAmt = 0.02 + aHigh * 0.12;
    float glitchFactor = sin(time_f * (30.0 + aPk * 30.0));
    vec4 glitchColor = texture(samp, tc + vec2(glitchFactor * glitchAmt));

    float blend1 = 0.4 + aLow * 0.2;
    float blend2 = 0.3 + aMid * 0.2;
    float blend3 = 0.3 + aHigh * 0.2;
    float total = blend1 + blend2 + blend3;
    color = (color1 * blend1 + color2 * blend2 + glitchColor * blend3) / total;
}
