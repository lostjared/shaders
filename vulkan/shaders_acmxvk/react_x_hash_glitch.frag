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
