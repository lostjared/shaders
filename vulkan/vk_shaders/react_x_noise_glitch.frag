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

    vec2 uv = tc;
    float glitchStrength = 0.02 + aPk * 0.15;
    float glitchHash = fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
    float glitchOffsetX = glitchHash * glitchStrength;
    float glitchOffsetY = fract(cos(dot(uv, vec2(4.898, 7.23))) * 23421.6312) * glitchStrength;

    uv.x += glitchOffsetX;
    uv.y += glitchOffsetY;

    vec4 colorA = texture(samp, uv);

    float noiseSpeed = 30.0 + aHigh * 40.0;
    float noiseAmt = 0.005 + aPk * 0.02;
    vec4 colorB = texture(samp, uv + vec2(noiseAmt * sin(time_f * noiseSpeed), noiseAmt * cos(time_f * noiseSpeed)));

    float noise = fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
    float mixAmt = noise * (0.3 + aMid * 0.5);
    color = mix(colorA, colorB, mixAmt);
}
