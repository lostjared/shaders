#version 330 core
// ant_gem_metal_pulse
// Pulsing metallic concentric rings with spectrum-reactive expansion

in vec2 tc;
out vec4 color;

uniform sampler2D samp;
uniform float time_f;
uniform vec2 iResolution;
uniform float amp_peak;
uniform float amp_smooth;
uniform sampler1D spectrum;

vec3 metalSpectrum(float t) {
    return vec3(0.5 + 0.5 * cos(6.28318 * (t + vec3(0.0, 0.33, 0.67))));
}

void main(void) {
    float bass   = texture(spectrum, 0.04).r;
    float mid    = texture(spectrum, 0.22).r;
    float hiMid  = texture(spectrum, 0.40).r;
    float treble = texture(spectrum, 0.58).r;
    float air    = texture(spectrum, 0.80).r;

    vec2 uv = tc * 2.0 - 1.0;
    uv.x *= iResolution.x / iResolution.y;

    float r = length(uv);
    float angle = atan(uv.y, uv.x);

    // Multiple ring sets pulsing outward
    float ringFreq1 = 15.0 + bass * 12.0;
    float ringSpeed1 = time_f * 4.0 + amp_peak * 2.0;
    float ring1 = sin(r * ringFreq1 - ringSpeed1);

    float ringFreq2 = 10.0 + mid * 8.0;
    float ringSpeed2 = time_f * 2.5;
    float ring2 = sin(r * ringFreq2 + ringSpeed2);

    // Angular ripple modulation
    float angRipple = sin(angle * (6.0 + treble * 8.0) + time_f) * 0.5 + 0.5;

    // Ring mask
    float ringMask1 = smoothstep(0.5, 1.0, ring1);
    float ringMask2 = smoothstep(0.3, 0.8, ring2);
    float combinedRing = max(ringMask1, ringMask2 * 0.7);

    // Pulse distortion on texture
    float pulseWarp = ring1 * 0.015 + ring2 * 0.01;
    vec2 dir = normalize(uv + 0.001);
    vec2 sampUV = tc + dir * pulseWarp;

    // Chromatic split
    float chroma = 0.008 + air * 0.02 + amp_peak * 0.01;
    vec3 baseTex;
    baseTex.r = texture(samp, sampUV + vec2(chroma, 0.0)).r;
    baseTex.g = texture(samp, sampUV).g;
    baseTex.b = texture(samp, sampUV - vec2(chroma, 0.0)).b;

    // Ring coloring: each ring gets spectrum color
    vec3 ringColor1 = metalSpectrum(r * 2.0 - time_f * 0.3);
    vec3 ringColor2 = metalSpectrum(r * 2.0 + time_f * 0.2 + 0.5);
    vec3 ringColor = mix(ringColor1, ringColor2, angRipple);

    vec3 finalColor = mix(baseTex, baseTex * ringColor, combinedRing * (0.4 + hiMid * 0.4));

    // Pulse glow: bright flash on ring crests
    float pulseGlow = pow(max(ring1, 0.0), 4.0) * (0.3 + bass * 0.5);
    finalColor += metalSpectrum(r + time_f * 0.15) * pulseGlow;

    // Central glow expands with smooth amplitude
    float lightRadius = 5.0 - amp_smooth * 3.5;
    float center = exp(-r * max(lightRadius, 0.5));
    finalColor += vec3(1.0, 0.97, 0.92) * center * (1.5 + amp_peak * 2.5);

    // Angular shimmer
    finalColor += ringColor * angRipple * air * 0.1;

    color = vec4(finalColor, 1.0);
}
