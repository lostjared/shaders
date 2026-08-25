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










float pingPong(float x, float length) {
    float modVal = mod(x, length * 2.0);
    return modVal <= length ? modVal : length * 2.0 - modVal;
}

void main(void) {
    float aLow  = clamp(amp_low,  0.0, 1.0);
    float aMid  = clamp(amp_mid,  0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float aPk   = clamp(amp_peak, 0.0, 1.0);
    float aRms  = clamp(amp_rms,  0.0, 1.0);

    float glitchStrength = 0.01 + aPk * 0.08;
    float speed = 8.0 + aRms * 15.0;
    float freqX = 20.0 + aLow * 20.0;
    float freqY = 20.0 + aHigh * 20.0;
    vec2 glitch = vec2(
        pingPong(time_f * speed + tc.y * freqX, 1.0) * glitchStrength,
        pingPong(time_f * speed + tc.x * freqY, 1.0) * glitchStrength
    );

    vec2 displacedTc = tc + glitch;

    float chromaStr = aPk * 0.015;
    float r = texture(samp, displacedTc + vec2(chromaStr, 0.0)).r;
    float g = texture(samp, displacedTc).g;
    float b = texture(samp, displacedTc - vec2(chromaStr, 0.0)).b;

    vec3 col = vec3(r, g, b);
    col *= 1.0 + aPk * 0.4;
    color = vec4(col, 1.0);
}
