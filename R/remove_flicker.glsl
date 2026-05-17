#version 330 core
in vec2 tc;
out vec4 color;

uniform float time_f;
uniform float time_speed;
uniform sampler2D samp;
uniform vec2 iResolution;
uniform vec4 iMouse;
uniform float amp;
uniform float uamp;
uniform float iTime;
uniform int iFrame;
uniform float iTimeDelta;
uniform vec4 iDate;
uniform vec2 iMouseClick;
uniform float iFrameRate;
uniform vec3 iChannelResolution[4];
uniform float iChannelTime[4];
uniform float iSampleRate;
uniform float amp_peak;
uniform float amp_rms;
uniform float amp_smooth;
uniform float amp_low;
uniform float amp_mid;
uniform float amp_high;
uniform float iamp;

// Standard perceptual luminance weights
float getLuminance(vec3 c) {
    return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

void main(void) {
    vec3 baseColor = texture(samp, tc).rgb;

    // 1. Sparse Sampling: Estimate global frame brightness
    // Sampling 9 points across the texture to calculate an average luminance
    float frameLuma = 0.0;
    frameLuma += getLuminance(texture(samp, vec2(0.1, 0.1)).rgb);
    frameLuma += getLuminance(texture(samp, vec2(0.5, 0.1)).rgb);
    frameLuma += getLuminance(texture(samp, vec2(0.9, 0.1)).rgb);
    frameLuma += getLuminance(texture(samp, vec2(0.1, 0.5)).rgb);
    frameLuma += getLuminance(texture(samp, vec2(0.5, 0.5)).rgb);
    frameLuma += getLuminance(texture(samp, vec2(0.9, 0.5)).rgb);
    frameLuma += getLuminance(texture(samp, vec2(0.1, 0.9)).rgb);
    frameLuma += getLuminance(texture(samp, vec2(0.5, 0.9)).rgb);
    frameLuma += getLuminance(texture(samp, vec2(0.9, 0.9)).rgb);
    frameLuma /= 9.0;

    // 2. Automatic Gain Control: Dampen bright flashes
    // Threshold determines the luminance level where dimming begins
    float threshold = 0.45; 
    float exposure = 1.0;

    if (frameLuma > threshold) {
        // Calculate a reduction multiplier
        float targetExposure = threshold / (frameLuma + 0.001);
        
        // Mix ratio (0.8) controls how aggressively the flash is suppressed.
        // 1.0 = strict cap at threshold, lower values allow some brightness through.
        exposure = mix(1.0, targetExposure, 0.8); 
    }

    // Apply the global exposure reduction
    vec3 adjustedColor = baseColor * exposure;

    // 3. Local Highlight Compression (Reinhard Tonemapping)
    // Softens individual bright pixels to prevent harsh clipping
    float pixelLuma = getLuminance(adjustedColor);
    float toneMappedLuma = pixelLuma / (1.0 + pixelLuma);

    // Reapply the compressed luminance while preserving the original color ratios
    if (pixelLuma > 0.001) {
        adjustedColor *= (toneMappedLuma / pixelLuma);
    }

    color = vec4(adjustedColor, 1.0);
}