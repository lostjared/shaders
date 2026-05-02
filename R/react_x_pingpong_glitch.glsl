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

float pingPong(float x, float length) {
    float modVal = mod(x, length * 2.0);
    return modVal <= length ? modVal : length * 2.0 - modVal;
}

void main(void) {
    float aLow = clamp(amp_low, 0.0, 1.0);
    float aMid = clamp(amp_mid, 0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float aPk = clamp(amp_peak, 0.0, 1.0);
    float aRms = clamp(amp_rms, 0.0, 1.0);

    float glitchStrength = 0.01 + aPk * 0.08;
    float speed = 8.0 + aRms * 15.0;
    float freqX = 20.0 + aLow * 20.0;
    float freqY = 20.0 + aHigh * 20.0;
    vec2 glitch = vec2(
        pingPong(time_f * speed + tc.y * freqX, 1.0) * glitchStrength,
        pingPong(time_f * speed + tc.x * freqY, 1.0) * glitchStrength);

    vec2 displacedTc = tc + glitch;

    float chromaStr = aPk * 0.015;
    float r = texture(samp, displacedTc + vec2(chromaStr, 0.0)).r;
    float g = texture(samp, displacedTc).g;
    float b = texture(samp, displacedTc - vec2(chromaStr, 0.0)).b;

    vec3 col = vec3(r, g, b);
    col *= 1.0 + aPk * 0.4;
    color = vec4(col, 1.0);
}
