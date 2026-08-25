#version 450

layout(set = 0, binding = 1, std140) uniform SpriteExtended {
    vec4 mouse;
    vec4 u0;
    vec4 u1;
    vec4 u2;
    vec4 u3;
    vec4 custom_uniforms[16];
    vec4 audio_bands;
    vec4 audio_history;
} ext;
#define amp_high ext.audio_bands.z
#define amp_low ext.audio_bands.x
#define amp_mid ext.audio_bands.y
#define amp_peak ext.u2.w
#define amp_rms ext.u3.z
#define amp_smooth ext.u3.w
#define iResolution ext.u0.zw
#define iamp ext.u1.z
#define time_f ext.u2.y

layout(location = 0) out vec4 color;
layout(location = 0) in vec2 tc;
layout(set = 0, binding = 0) uniform sampler2D samp;










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
