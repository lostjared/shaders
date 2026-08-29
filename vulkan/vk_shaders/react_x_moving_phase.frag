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

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;

layout(set = 0, binding = 0) uniform sampler2D samp;









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
