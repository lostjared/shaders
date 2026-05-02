#version 330 core
out vec4 color;
in vec2 tc;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_rms;
uniform float amp_smooth;
uniform float amp_low;
uniform float amp_mid;
uniform float amp_high;
uniform float iamp;

void main(void) {
    float aLow = clamp(amp_low, 0.0, 1.0);
    float aMid = clamp(amp_mid, 0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float aPk = clamp(amp_peak, 0.0, 1.0);
    float aRms = clamp(amp_rms, 0.0, 1.0);

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
