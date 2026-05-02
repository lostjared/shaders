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

vec3 spectrum(float t) {
    return vec3(0.5 + 0.5 * cos(6.28318 * (t + vec3(0.0, 0.33, 0.67))));
}

float fractalNoise(vec2 uv) {
    float n = 0.0;
    float a = 1.0;
    for (int i = 0; i < 5; ++i) {
        n += a * texture(samp, uv).r;
        uv = fract(uv * 2.0);
        a *= 0.5;
    }
    return n / (1.0 - 0.5);
}

void main(void) {
    float aLow = clamp(amp_low, 0.0, 1.0);
    float aMid = clamp(amp_mid, 0.0, 1.0);
    float aHigh = clamp(amp_high, 0.0, 1.0);
    float aPk = clamp(amp_peak, 0.0, 1.0);
    float aRms = clamp(amp_rms, 0.0, 1.0);

    vec2 uv = tc * 2.0 - 1.0;
    uv.x *= iResolution.x / iResolution.y;

    float r = length(uv);
    float angle = atan(uv.y, uv.x);

    float noiseScale = 5.0 + aLow * 5.0;
    float noiseValue = fractalNoise(tc * noiseScale) * 0.1;

    float rippleFreq = 10.0 + aLow * 15.0;
    float rippleSpeed = mix(1.0, 4.0, aRms);
    float ripple = sin(angle * rippleFreq + time_f * rippleSpeed + noiseValue) * 0.03;
    ripple += sin(angle * 25.0 - time_f * 2.0) * (0.01 + aHigh * 0.02);

    float waveFreq = 20.0 + aMid * 15.0;
    float wave = sin(r * waveFreq - time_f * 4.0 + ripple * 10.0);

    float shift = ripple * (0.5 + aPk * 1.0) + wave * 0.01;

    float r_chan = texture(samp, tc + vec2(shift, 0.0)).r;
    float g_chan = texture(samp, tc).g;
    float b_chan = texture(samp, tc - vec2(shift, 0.0)).b;
    vec3 baseTex = vec3(r_chan, g_chan, b_chan);

    vec3 rainbow = spectrum(r - time_f * 0.5 + ripple + noiseValue * 0.2 + aHigh);
    float glowMask = smoothstep(0.5, 1.0, wave);

    vec3 coreGlow = vec3(1.0, 0.98, 0.9) * pow(wave, 2.0) * (1.5 + aPk * 2.0);

    float rainbowMix = 0.25 + aMid * 0.25;
    vec3 finalColor = mix(baseTex, rainbow, glowMask * rainbowMix);
    finalColor = finalColor * sin(coreGlow * time_f);

    float metalSheen = wave * ripple * (2.0 + aLow * 3.0);
    finalColor += metalSheen + noiseValue * 0.1;

    finalColor *= 1.0 + aPk * 0.5;

    color = vec4(finalColor, 1.0);
}
