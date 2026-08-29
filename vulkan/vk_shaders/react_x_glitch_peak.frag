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
#define iamp ext.u1.z
#define time_f ext.u2.y

layout(location = 0) in vec2 tc;
layout(location = 0) out vec4 color;
layout(set = 0, binding = 0) uniform sampler2D samp;









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
